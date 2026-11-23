#!/usr/bin/env python3
"""Compare generated trees, ignoring SwiftPM state and relocating workspace-local links."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def snapshot(source, destination, normalized_root):
    prefixes = {str(source.absolute()), str(source.resolve(strict=True))}
    source = source.resolve(strict=True)
    if not source.is_dir():
        raise NotADirectoryError(source)

    def copy_tree(current, output):
        output.mkdir()
        for entry in current.iterdir():
            if entry.name == ".build":
                continue
            copied = output / entry.name
            if entry.is_symlink():
                target = os.readlink(entry)
                for prefix in prefixes:
                    if target == prefix or target.startswith(prefix + "/"):
                        target = str(normalized_root) + target[len(prefix):]
                        break
                copied.symlink_to(target)
            elif entry.is_dir():
                copy_tree(entry, copied)
            else:
                shutil.copy2(entry, copied)

    copy_tree(source, destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("generated", type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="bazelize-workspace-parity-") as directory:
        root = Path(directory)
        reference = root / "pbxproj"
        generated = root / "xcproj"
        snapshot(args.reference, reference, root / "workspace")
        snapshot(args.generated, generated, root / "workspace")
        return subprocess.run([
            "git", "diff", "--no-index", "--exit-code", str(reference), str(generated),
        ]).returncode


if __name__ == "__main__":
    raise SystemExit(main())
