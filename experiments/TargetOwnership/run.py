#!/usr/bin/env python3
"""Probe Swift ownership contracts and benchmark real loaded Xcode.Target data.

Requires the selected Xcode toolchain. The isolated UniqueArray benchmark needs
macOS 27 and Swift 6.4; the production package's deployment floor is unchanged.
Example:
  python3 experiments/TargetOwnership/run.py --project fixture/iOS/Example.xcodeproj --output /tmp/ownership.json
"""

import argparse
import hashlib
import json
import platform
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
LINK_MODULES = ("Xcode", "PathKit", "AnyCodable", "XcodeProj", "XcodeProjectFormat", "AEXML")


def command(arguments, *, check=True):
    result = subprocess.run([str(value) for value in arguments], cwd=ROOT, capture_output=True, text=True)
    if check and result.returncode:
        raise RuntimeError(f"Command failed: {arguments!r}\n{result.stdout}\n{result.stderr}")
    return result


def probe(name, deployment):
    arguments = ["swiftc", "-swift-version", "6", "-target", f"{platform.machine()}-apple-macos{deployment}",
                 "-typecheck", HERE / "Probes" / f"{name}.swift"]
    result = command(arguments, check=False)
    return {"probe": name, "deployment": deployment, "command": [str(value) for value in arguments],
            "exit_code": result.returncode, "diagnostics": result.stdout + result.stderr}


def median(values):
    return {"median_seconds": statistics.median(values), "min_seconds": min(values),
            "max_seconds": max(values), "samples_seconds": values}


def benchmark(args, work):
    build = ["swift", "build", "--build-system", "native", "--scratch-path", work / "build", "-c", "release"]
    print("Building the production CLI and model in an isolated native SwiftPM cache...", file=sys.stderr)
    command([*build, "--product", "bazelize"])
    binary_directory = Path(command([*build, "--show-bin-path"]).stdout.strip())
    objects = []
    for module in LINK_MODULES:
        module_objects = sorted((binary_directory / f"{module}.build").glob("*.o"))
        if not module_objects:
            raise RuntimeError(f"No object files for {module} under {binary_directory}; native build layout changed")
        objects.extend(module_objects)
    binary = work / "target-ownership"
    compile_arguments = ["swiftc", "-O", "-swift-version", "6", "-parse-as-library",
                         "-target", f"{platform.machine()}-apple-macos27.0",
                         "-module-cache-path", work / "module-cache",
                         "-I", binary_directory / "Modules", HERE / "Benchmark.swift"]
    command([*compile_arguments, *objects, "-o", binary])
    # Inspect optimized ownership conventions rather than assuming a struct
    # parameter is copied just because its source lacks `borrowing`.
    sil = command([*compile_arguments, "-emit-sil"]).stdout
    signatures = [line for line in sil.splitlines() if line.startswith("sil ")
                  and any(name in line for name in ("defaultChecksum", "borrowedChecksum", "ownedChecksum"))]
    result = json.loads(command([binary, args.project, str(args.iterations), str(args.samples)]).stdout)
    result["timings"] = {name: median(values) for name, values in result.pop("seconds").items()}
    result["kernel_sil_signatures"] = signatures
    result["compiler_arguments"] = [str(value) for value in compile_arguments]
    result["linked_modules"] = list(LINK_MODULES)
    result["scope"] = "Repeated read-only traversal; excludes model loading, projection, validation, compilation, and generation"
    result["caveat"] = "Array versus UniqueArray also changes the container; compare the two UniqueArray modes separately. The local experimental type and imported production type may optimize differently. No end-to-end speedup is established."
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", type=Path, default=ROOT / "fixture/iOS/Example.xcodeproj")
    parser.add_argument("--iterations", type=int, default=100000)
    parser.add_argument("--samples", type=int, default=8)
    parser.add_argument("--work-dir", type=Path, help="Reuse this isolated build directory between measurements")
    parser.add_argument("--output", type=Path, help="Write raw samples and metadata as JSON; otherwise print them")
    parser.add_argument("--probes-only", action="store_true", help="Run compiler compatibility probes without the macOS 27 benchmark")
    args = parser.parse_args()
    if platform.system() != "Darwin":
        parser.error("this experiment uses the repository's macOS Xcode model loader")
    if args.iterations <= 0 or args.samples < 4:
        parser.error("iterations must be positive and samples must be at least four")
    args.project = args.project.resolve()
    revision = command(["git", "-C", args.project.parent, "rev-parse", "HEAD"], check=False)
    project_files = [args.project / "project.pbxproj", args.project / "project.xcproj"]
    result = {"swift_version": command(["swiftc", "--version"]).stdout.strip(),
              "host": platform.platform(), "architecture": platform.machine(),
              "cpu": command(["sysctl", "-n", "machdep.cpu.brand_string"]).stdout.strip(),
              "project_revision": revision.stdout.strip() if revision.returncode == 0 else None,
              "repository_revision": command(["git", "rev-parse", "HEAD"]).stdout.strip(),
              "project_files_sha256": {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                                       for path in project_files if path.is_file()},
              "benchmark_source_sha256": hashlib.sha256((HERE / "Benchmark.swift").read_bytes()).hexdigest(),
              "production_deployment": "macOS 14", "benchmark_deployment": "macOS 27",
              "probes": [probe("Encoding", "14.0"), probe("Array", "14.0"),
                         probe("UniqueArray", "14.0"), probe("UniqueArray", "27.0")]}
    if not args.probes_only:
        if int(platform.mac_ver()[0].split(".")[0]) < 27:
            parser.error("the native noncopyable-container benchmark needs macOS 27; use --probes-only on older hosts")
        if not args.project.exists():
            parser.error(f"project does not exist: {args.project}; generate the fixture with Tuist or provide --project")
        if args.work_dir:
            args.work_dir = args.work_dir.resolve()
            args.work_dir.mkdir(parents=True, exist_ok=True)
            result["benchmark"] = benchmark(args, args.work_dir)
        else:
            with tempfile.TemporaryDirectory(prefix="bazelize-ownership-") as directory:
                result["benchmark"] = benchmark(args, Path(directory))
    text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(text)
        print(f"Wrote raw experiment results to {args.output}", file=sys.stderr)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
