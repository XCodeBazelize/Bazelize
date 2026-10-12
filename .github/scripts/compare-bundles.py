#!/usr/bin/env python3
"""Compare a native Apple bundle with the bundle Bazelize generated.

The comparison is symmetric: a missing, extra, structurally different, or
content-different entry fails unless that exact difference has a documented
baseline entry. SwiftPM resource bundles have two platform layouts, so their
physical wrapper is normalized while their logical resource contents are
compared.
"""

import argparse
import json
import plistlib
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from xml.parsers.expat import ExpatError


@dataclass(frozen=True)
class Difference:
    identifier: str
    message: str


def is_ignored(relative: Path) -> bool:
    return "_CodeSignature" in relative.parts or relative.name in {
        "CodeResources",
        ".DS_Store",
    }


def node_kind(path: Path) -> str:
    if path.is_symlink():
        return "symlink"
    if path.is_dir():
        return "directory"
    return "file"


def resource_entries(root: Path) -> tuple[dict[str, Path], str]:
    contents = root / "Contents"
    resources = contents / "Resources"
    if resources.is_dir():
        payload = resources
        info_plist = contents / "Info.plist"
        layout = "wrapped"
    else:
        payload = root
        info_plist = root / "Info.plist"
        layout = "flat"

    entries = entries_below(payload)
    if info_plist.is_file():
        entries["Info.plist"] = info_plist
    return entries, layout


def entries_below(root: Path) -> dict[str, Path]:
    entries = {}
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        if is_ignored(relative):
            continue
        entries[relative.as_posix()] = path
    return entries


def load_plist(path: Path) -> tuple[bool, Any]:
    if path.suffix not in {".plist", ".strings"}:
        return False, None

    data = path.read_bytes()
    try:
        return True, plistlib.loads(data)
    except (ExpatError, plistlib.InvalidFileException, ValueError):
        pass

    # xcstrings may emit an XML plist as UTF-16 while retaining an UTF-8 XML
    # declaration. Decode the BOM and re-encode consistently before parsing.
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        try:
            return True, plistlib.loads(data.decode("utf-16").encode("utf-8"))
        except (
            ExpatError,
            UnicodeDecodeError,
            plistlib.InvalidFileException,
            ValueError,
        ):
            pass
    return False, None


def plist_differences(
    path: str,
    reference: Any,
    generated: Any,
    key_path: str = "",
) -> list[Difference]:
    identifier = f"plist:{path}:{key_path or '/'}"
    if type(reference) is not type(generated):
        return [
            Difference(
                identifier,
                f"{path}{key_path}: plist types differ "
                f"({type(reference).__name__} != {type(generated).__name__})",
            )
        ]

    if isinstance(reference, dict):
        differences = []
        for key in sorted(reference.keys() | generated.keys()):
            child = f"{key_path}/{key}"
            if key not in reference:
                differences.append(
                    Difference(
                        f"plist:{path}:{child}",
                        f"{path}{child}: only in generated plist",
                    )
                )
            elif key not in generated:
                differences.append(
                    Difference(
                        f"plist:{path}:{child}",
                        f"{path}{child}: only in reference plist",
                    )
                )
            else:
                differences += plist_differences(
                    path,
                    reference[key],
                    generated[key],
                    child,
                )
        return differences

    if isinstance(reference, list):
        if len(reference) != len(generated):
            return [
                Difference(
                    identifier,
                    f"{path}{key_path}: plist list lengths differ "
                    f"({len(reference)} != {len(generated)})",
                )
            ]
        differences = []
        for index, (reference_item, generated_item) in enumerate(
            zip(reference, generated)
        ):
            differences += plist_differences(
                path,
                reference_item,
                generated_item,
                f"{key_path}/{index}",
            )
        return differences

    if reference != generated:
        return [
            Difference(
                identifier,
                f"{path}{key_path}: plist values differ "
                f"({reference!r} != {generated!r})",
            )
        ]
    return []


MACHO_MAGICS = {
    b"\xca\xfe\xba\xbe",
    b"\xcf\xfa\xed\xfe",
    b"\xce\xfa\xed\xfe",
    b"\xfe\xed\xfa\xce",
    b"\xfe\xed\xfa\xcf",
}


def is_macho(path: Path) -> bool:
    with path.open("rb") as file:
        return file.read(4) in MACHO_MAGICS


def command_output(*arguments: str | Path) -> list[str]:
    result = subprocess.run(
        [str(argument) for argument in arguments],
        capture_output=True,
        check=True,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def asset_catalog_values(path: Path) -> Any:
    values = json.loads(
        "\n".join(
            command_output(
                "xcrun",
                "--sdk",
                "macosx",
                "assetutil",
                "--info",
                path,
            )
        )
    )
    # assetutil exposes build-tool metadata in the catalog header and internal
    # rendition bookkeeping. Neither changes what CoreUI serves to a consumer.
    # Keep schema, platform, traits, names, and decoded rendition values strict.
    header_metadata = {
        "AssetStorageVersion",
        "Authoring Tool",
        "CoreUIVersion",
        "DumpToolVersion",
        "MainVersion",
        "Timestamp",
    }
    rendition_metadata = {
        "NameIdentifier",
        "SHA1Digest",
        "SizeOnDisk",
    }
    if isinstance(values, list):
        for index, value in enumerate(values):
            if not isinstance(value, dict):
                continue
            for key in header_metadata if index == 0 else rendition_metadata:
                value.pop(key, None)
    return values


def asset_catalog_differences(
    path: str,
    reference: Path,
    generated: Path,
) -> list[Difference]:
    if asset_catalog_values(reference) == asset_catalog_values(generated):
        return []
    return [
        Difference(
            f"asset:{path}",
            f"{path}: asset catalog metadata or renditions differ",
        )
    ]


def normalize_rpath(path: str) -> str:
    path = re.sub(
        r"^/(?:private/var/select/developer_dir|var/db/xcode_select_link)",
        "$DEVELOPER_DIR",
        path,
    )
    return re.sub(r"/swift-\d+(?:\.\d+)?/", "/swift-$VERSION/", path)


def macho_values(path: Path) -> dict[str, tuple[str, ...]]:
    load_commands = command_output("otool", "-l", path)
    rpaths = []
    for index, line in enumerate(load_commands):
        if line == "cmd LC_RPATH":
            value = load_commands[index + 2]
            rpath = value.removeprefix("path ").rsplit(" (offset ", 1)[0]
            rpaths.append(normalize_rpath(rpath))

    dependencies = []
    for value in command_output("otool", "-L", path)[1:]:
        dependency, _, metadata = value.partition(" (")
        dependencies.append(
            f"{dependency} [weak]" if metadata.endswith(", weak)") else dependency
        )

    build = command_output("xcrun", "vtool", "-show-build", path)[1:]
    exports = command_output("nm", "-gjU", path)
    return {
        "architectures": tuple(command_output("lipo", "-archs", path)),
        "build": tuple(build),
        "dependencies": tuple(dependencies),
        "exports": tuple(exports),
        "filetype": tuple(command_output("file", "-b", path)),
        "rpaths": tuple(rpaths),
    }


def macho_differences(
    path: str,
    reference: Path,
    generated: Path,
) -> list[Difference]:
    reference_values = macho_values(reference)
    generated_values = macho_values(generated)
    differences = []

    for key in ("dependencies", "exports", "rpaths"):
        reference_items = set(reference_values[key])
        generated_items = set(generated_values[key])
        for item in sorted(reference_items - generated_items):
            differences.append(
                Difference(
                    f"macho:{path}:{key}:missing:{item}",
                    f"{path}: Mach-O {key} has only the reference item {item!r}",
                )
            )
        for item in sorted(generated_items - reference_items):
            differences.append(
                Difference(
                    f"macho:{path}:{key}:extra:{item}",
                    f"{path}: Mach-O {key} has only the generated item {item!r}",
                )
            )

    for key in ("architectures", "build", "filetype"):
        if reference_values[key] != generated_values[key]:
            differences.append(
                Difference(
                    f"macho:{path}:{key}",
                    f"{path}: Mach-O {key} differ "
                    f"({reference_values[key]!r} != {generated_values[key]!r})",
                )
            )
    return differences


def compare_entries(
    reference: dict[str, Path],
    generated: dict[str, Path],
) -> list[Difference]:
    differences = []
    reference_paths = set(reference)
    generated_paths = set(generated)

    for path in sorted(reference_paths - generated_paths):
        differences.append(
            Difference(f"missing:{path}", f"only in reference bundle: {path}")
        )
    for path in sorted(generated_paths - reference_paths):
        differences.append(
            Difference(f"extra:{path}", f"only in generated bundle: {path}")
        )

    for path in sorted(reference_paths & generated_paths):
        reference_path = reference[path]
        generated_path = generated[path]
        reference_kind = node_kind(reference_path)
        generated_kind = node_kind(generated_path)
        if reference_kind != generated_kind:
            differences.append(
                Difference(
                    f"type:{path}",
                    f"{path}: node types differ "
                    f"({reference_kind} != {generated_kind})",
                )
            )
            continue

        if reference_kind == "directory":
            continue
        if reference_kind == "symlink":
            reference_target = reference_path.readlink()
            generated_target = generated_path.readlink()
            if reference_target != generated_target:
                differences.append(
                    Difference(
                        f"symlink:{path}",
                        f"{path}: symlink targets differ "
                        f"({reference_target} != {generated_target})",
                    )
                )
            continue

        reference_executable = bool(reference_path.stat().st_mode & 0o111)
        generated_executable = bool(generated_path.stat().st_mode & 0o111)
        if reference_executable != generated_executable:
            differences.append(
                Difference(
                    f"executable:{path}",
                    f"{path}: executable bits differ "
                    f"({reference_executable} != {generated_executable})",
                )
            )

        if reference_path.read_bytes() == generated_path.read_bytes():
            continue

        if reference_path.name == "Assets.car":
            differences += asset_catalog_differences(
                path,
                reference_path,
                generated_path,
            )
        else:
            reference_is_plist, reference_plist = load_plist(reference_path)
            generated_is_plist, generated_plist = load_plist(generated_path)
            if reference_is_plist and generated_is_plist:
                differences += plist_differences(
                    path,
                    reference_plist,
                    generated_plist,
                )
            elif is_macho(reference_path) and is_macho(generated_path):
                differences += macho_differences(
                    path,
                    reference_path,
                    generated_path,
                )
            else:
                differences.append(
                    Difference(
                        f"content:{path}",
                        f"{path}: file contents differ",
                    )
                )
    return differences


def load_baseline(path: Path | None, bundle: str) -> dict[str, str]:
    if path is None:
        return {}
    data = json.loads(path.read_text())
    baseline = data.get("bundles", {}).get(bundle, {})
    if not isinstance(baseline, dict) or not all(
        isinstance(identifier, str) and isinstance(reason, str)
        for identifier, reason in baseline.items()
    ):
        raise ValueError(f"invalid baseline for {bundle} in {path}")
    return baseline


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--reference",
        required=True,
        type=Path,
        help="the bundle produced by Xcode or SwiftPM",
    )
    parser.add_argument(
        "--generated",
        required=True,
        type=Path,
        help="the bundle produced by the generated Bazel workspace",
    )
    parser.add_argument(
        "--swiftpm-resource",
        action="store_true",
        help="compare logical contents across wrapped and flat resource layouts",
    )
    parser.add_argument(
        "--baseline",
        type=Path,
        help="documented differences accepted for this bundle",
    )
    arguments = parser.parse_args()

    for bundle in (arguments.reference, arguments.generated):
        if not bundle.is_dir():
            print(f"::error::no bundle at {bundle}")
            return 1

    bundle_name = arguments.reference.name
    differences = []
    if bundle_name != arguments.generated.name:
        differences.append(
            Difference(
                "bundle-name",
                f"bundle names differ "
                f"({bundle_name} != {arguments.generated.name})",
            )
        )

    if arguments.swiftpm_resource:
        reference, reference_layout = resource_entries(arguments.reference)
        generated, generated_layout = resource_entries(arguments.generated)
        if reference_layout != generated_layout:
            print(
                "::notice::accepted SwiftPM resource layout difference: "
                f"reference is {reference_layout}, generated is {generated_layout}"
            )
    else:
        reference = entries_below(arguments.reference)
        generated = entries_below(arguments.generated)

    differences += compare_entries(reference, generated)

    try:
        baseline = load_baseline(arguments.baseline, bundle_name)
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"::error::{error}")
        return 1

    observed = {difference.identifier for difference in differences}
    for difference in differences:
        if difference.identifier in baseline:
            print(
                f"::notice::accepted difference {difference.identifier}: "
                f"{difference.message}; {baseline[difference.identifier]}"
            )
        else:
            print(f"::error::{difference.identifier}: {difference.message}")

    stale = sorted(set(baseline) - observed)
    for identifier in stale:
        print(
            f"::error::baseline difference no longer occurs: "
            f"{identifier}; remove it"
        )

    unexpected = observed - set(baseline)
    if unexpected or stale:
        return 1

    print(
        f"{bundle_name}: {len(reference)} entries match with "
        f"{len(differences)} documented differences"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
