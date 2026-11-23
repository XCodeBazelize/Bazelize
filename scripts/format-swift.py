#!/usr/bin/env python3
"""Format changed project Swift files, or check staged blobs without editing them."""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(subprocess.check_output(
    ["git", "rev-parse", "--show-toplevel"], text=True).strip())
PROJECT_PATHS = ["Package.swift", "Sources", "Tests", "Plugins", "fixture/iOS", "spm"]


def git(*arguments):
    return subprocess.check_output(["git", *arguments], cwd=ROOT)


def swift_files(paths):
    return sorted({os.fsdecode(path) for path in paths.split(b"\0")
                   if path.endswith(b".swift")})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--staged-check", action="store_true")
    parser.add_argument("--base", default="HEAD",
                        help="Format changes since the merge base with this ref (use the PR base).")
    args = parser.parse_args()

    if args.staged_check:
        paths = git("diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z",
                    "--", *PROJECT_PATHS)
    else:
        base = os.fsdecode(git("merge-base", "HEAD", args.base)).strip()
        paths = git("diff", base, "--name-only", "--diff-filter=ACMR", "-z",
                    "--", *PROJECT_PATHS)
        paths += git("ls-files", "--others", "--exclude-standard", "-z", "--", *PROJECT_PATHS)
    files = swift_files(paths)
    if not files:
        print("No changed project Swift files.")
        return 0

    # mise selects the version pinned in mise.toml. Do not use a runner's or
    # contributor's unrelated SwiftFormat version.
    formatter = ["mise", "exec", "--", "swiftformat"]
    if not args.staged_check:
        files = [path for path in files if (ROOT / path).is_file() and not (ROOT / path).is_symlink()]
        if not files:
            return 0
        return subprocess.run(
            [*formatter, "--config", str(ROOT / ".swiftformat"), *files], cwd=ROOT).returncode

    # Check exactly the committed blob and configuration, not an unstaged edit.
    # Never rewrite the working tree or the index, and never stage files for users.
    with tempfile.TemporaryDirectory(prefix="bazelize-style-") as directory:
        config = Path(directory) / ".swiftformat"
        config.write_bytes(git("show", ":.swiftformat"))
        failed = False
        for path in files:
            mode = git("ls-files", "--stage", "--", path).split(b" ", 1)[0]
            if mode == b"120000":
                continue
            result = subprocess.run(
                [*formatter, "stdin", "--stdin-path", str(ROOT / path),
                 "--config", str(config), "--lint"],
                input=git("show", f":{path}"), cwd=ROOT)
            if result.returncode:
                print(f"SwiftFormat check failed for staged file: {path}", file=sys.stderr)
                failed = True
        if failed:
            print("Run `make format`, review the changes, and stage the intended result again. "
                  "Partially staged files may need formatting separately.", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        print(f"Local formatting failed: {error}. Run `mise install swiftformat` first.", file=sys.stderr)
        sys.exit(1)
