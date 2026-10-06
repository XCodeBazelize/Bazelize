#!/usr/bin/env python3
"""Compare what Xcode put in an app bundle with what the generated build did.

A generated build that compiles proves nothing about what it ships: a resource
Xcode copies and Bazel does not is a bug that only shows at run time. This reads
both bundles and reports every path Xcode has and Bazel does not.

Linking differs on purpose — Xcode embeds a package product as a framework and
the generated build links it statically — so the comparison is about resources,
not about the frameworks a bundle carries.
"""

import argparse
import sys
from pathlib import Path

# Paths whose absence means nothing: the signature is the signer's, the
# frameworks are a linking decision, and a compiled asset catalog is one file in
# both bundles whatever went into it.
IGNORED_PREFIXES = (
    "_CodeSignature/",
    "Frameworks/",
    "PlugIns/",
    "Contents/_CodeSignature/",
    "Contents/Frameworks/",
    "Contents/PlugIns/",
)

IGNORED_NAMES = {
    "PkgInfo",
    "embedded.mobileprovision",
    "CodeResources",
    ".DS_Store",
}


def bundle_files(root: Path) -> set[str]:
    files = set()
    for path in root.rglob("*"):
        if not path.is_file() and not path.is_symlink():
            continue
        relative = path.relative_to(root).as_posix()
        if relative.startswith(IGNORED_PREFIXES):
            continue
        if path.name in IGNORED_NAMES:
            continue
        files.add(relative)
    return files


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xcode", required=True, type=Path, help="the .app Xcode built")
    parser.add_argument("--bazel", required=True, type=Path, help="the .app the generated build produced")
    arguments = parser.parse_args()

    for bundle in (arguments.xcode, arguments.bazel):
        if not bundle.is_dir():
            print(f"::error::no bundle at {bundle}")
            return 1

    xcode = bundle_files(arguments.xcode)
    bazel = bundle_files(arguments.bazel)

    missing = sorted(xcode - bazel)
    extra = sorted(bazel - xcode)

    for path in extra:
        print(f"only in the generated bundle: {path}")

    if not missing:
        print(f"the generated bundle carries all {len(xcode)} compared paths")
        return 0

    for path in missing:
        print(f"::error::Xcode ships this and the generated build does not: {path}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
