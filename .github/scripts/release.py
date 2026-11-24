#!/usr/bin/env python3
"""Prepare releases only from a numeric tag whose exact commit passed both CI workflows."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile
import time


VERSION = re.compile(r"v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")
WORKFLOWS = ("swift.yml", "compatibility.yml")


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def version(tag):
    match = VERSION.fullmatch(tag)
    if not match:
        raise ValueError(f"Not a stable version tag: {tag}")
    return tuple(map(int, match.groups()))


def successful_run(runs, tag, sha):
    matching = [r for r in runs if r["head_sha"] == sha
                and r["head_branch"] == tag and r["event"] == "push"]
    if not matching:
        return None
    latest = max(matching, key=lambda r: r["id"])
    if latest["status"] != "completed":
        return None
    if latest["conclusion"] != "success":
        raise ValueError(f"Required tag CI did not pass: {latest['html_url']}")
    return latest


def previous_tag(tags, tag):
    current = version(tag)
    candidates = [(version(t), t) for t in tags if VERSION.fullmatch(t)
                  and version(t) < current]
    if not candidates:
        raise ValueError("No previous numeric ancestor tag; establish the initial release manually")
    return max(candidates)[1]


def gate(args):
    if not VERSION.fullmatch(args.tag):
        print("Not a stable release tag; skipping")
        return {}
    resolved = run("git", "rev-parse", f"refs/tags/{args.tag}^{{commit}}")
    if resolved != args.sha:
        raise ValueError("Tag no longer points to the CI commit")
    subprocess.run(["git", "merge-base", "--is-ancestor", args.sha,
                    "refs/remotes/origin/master"], check=True)
    while True:
        verified = {}
        for workflow in WORKFLOWS:
            pages = json.loads(run("gh", "api", "--paginate", "--slurp",
                f"repos/{args.repository}/actions/workflows/{workflow}/runs?head_sha={args.sha}&event=push&per_page=100"))
            result = successful_run([r for page in pages for r in page["workflow_runs"]],
                                    args.tag, args.sha)
            if result is None:
                print(f"Waiting for {workflow} on {args.tag} ({args.sha})")
            else:
                verified[workflow] = result
        if len(verified) == len(WORKFLOWS):
            print("Both required tag workflows passed")
            return {"run_id": str(verified["swift.yml"]["id"])}
        time.sleep(30)


def package(args):
    version(args.tag)
    binary = args.binary.resolve()
    if run(str(binary), "--version") != args.tag.removeprefix("v"):
        raise ValueError("Binary --version does not match the tag")
    architectures = set(run("lipo", "-archs", str(binary)).split())
    if architectures != {"arm64", "x86_64"}:
        raise ValueError(f"Expected macOS universal binary, got {architectures}")
    args.output.mkdir(parents=True, exist_ok=True)
    archive = args.output / "bazelize-macos-universal.tar.gz"
    with tarfile.open(archive, "w:gz") as output:
        info = output.gettarinfo(str(binary), arcname="bazelize")
        info.mode = 0o755
        with binary.open("rb") as source:
            output.addfile(info, source)
    with archive.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    (args.output / "SHA256SUMS").write_text(f"{digest}  {archive.name}\n")
    print(f"Packaged {args.tag}: {archive}")
    return {}


def notes(args):
    version(args.tag)
    # --merged excludes version tags on unrelated or future history; temp is not a version.
    tags = run("git", "tag", "--merged", args.sha).splitlines()
    previous = previous_tag(tags, args.tag)
    body = run("gh", "api", f"repos/{args.repository}/releases/generate-notes",
               "-f", f"tag_name={args.tag}", "-f", f"target_commitish={args.sha}",
               "-f", f"previous_tag_name={previous}", "-f",
               "configuration_file_path=.github/release.yml", "--jq", ".body")
    args.output.write_text(body + f"\n\nSource commit: `{args.sha}`.\n")
    print(f"Generated notes from {previous} to {args.tag}")
    return {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser("gate")
    check.add_argument("--tag", required=True)
    check.add_argument("--sha", required=True)
    check.add_argument("--repository", required=True)
    check.set_defaults(function=gate)
    archive = commands.add_parser("package")
    archive.add_argument("--tag", required=True)
    archive.add_argument("--binary", type=Path, required=True)
    archive.add_argument("--output", type=Path, required=True)
    archive.set_defaults(function=package)
    changes = commands.add_parser("notes")
    changes.add_argument("--tag", required=True)
    changes.add_argument("--sha", required=True)
    changes.add_argument("--repository", required=True)
    changes.add_argument("--output", type=Path, required=True)
    changes.set_defaults(function=notes)
    args = parser.parse_args()
    outputs = args.function(args)
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            for key, value in outputs.items():
                output.write(f"{key}={value}\n")


if __name__ == "__main__":
    main()
