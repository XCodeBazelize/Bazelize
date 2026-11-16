#!/usr/bin/env python3
"""Build the same warning-producing package as a root, local and external dependency."""

import subprocess
import sys
import tempfile
from pathlib import Path


def run(arguments, cwd):
    result = subprocess.run(arguments, cwd=cwd, text=True, capture_output=True)
    if result.returncode:
        print(result.stdout + result.stderr, file=sys.stderr)
        result.check_returncode()
    return result.stdout


def expect_warning_error(arguments, cwd):
    result = subprocess.run(arguments, cwd=cwd, text=True, capture_output=True)
    output = result.stdout + result.stderr
    warning_error = any("error:" in line and "dependency warning policy probe" in line
                        for line in output.splitlines())
    if result.returncode == 0 or not warning_error:
        print(output, file=sys.stderr)
        raise RuntimeError(f"Expected the fixture's warning to fail: {arguments}")
    print(f"{cwd.name}: warning remains an error")


def write(path, contents):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents)


def main():
    bazelize = str(Path(sys.argv[1]).resolve())
    with tempfile.TemporaryDirectory(prefix="bazelize-warnings-") as directory:
        root = Path(directory).resolve()
        dependency = root / "WarningDependency"
        write(dependency / "Package.swift", '''// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "WarningDependency",
    products: [.library(name: "WarningDependency", targets: ["WarningDependency"])],
    targets: [.target(name: "WarningDependency", swiftSettings: [
        .treatAllWarnings(as: .error, .when(configuration: .debug)),
        .treatWarning("DeprecatedDeclaration", as: .error),
    ])])
''')
        write(dependency / "Sources/WarningDependency/Warning.swift", '''
#warning("dependency warning policy probe")
@available(*, deprecated, message: "warning policy deprecation probe")
private func oldValue() -> Int { 68 }
public func warningValue() -> Int { oldValue() }
''')
        run(["git", "init", "-b", "fixture"], dependency)
        run(["git", "add", "Package.swift", "Sources"], dependency)
        run(["git", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
             "commit", "-m", "Warning fixture"], dependency)

        # Root diagnostics must still obey the manifest's warning controls.
        expect_warning_error(["swift", "build"], dependency)
        root_output = root / "RootApp"
        run([bazelize, "--input", str(dependency), "--output", str(root_output)], root)
        expect_warning_error(["bazel", "--batch", "build", "//Packages/WarningDependency:WarningDependency"], root_output)

        for origin in ("Local", "External"):
            consumer = root / origin
            requirement = (f'.package(path: "{dependency}")' if origin == "Local" else
                           f'.package(url: "{dependency.as_uri()}", branch: "fixture")')
            write(consumer / "Package.swift", f'''// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "{origin}",
    dependencies: [{requirement}],
    targets: [.executableTarget(name: "{origin}", dependencies: [
        .product(name: "WarningDependency", package: "WarningDependency"),
    ])])
''')
            write(consumer / f"Sources/{origin}/main.swift", '''import WarningDependency
precondition(warningValue() == 68)
print("warning dependency executed")
''')
            if origin == "Local":
                expect_warning_error(["swift", "build"], consumer)
            else:
                run(["swift", "run", origin], consumer)
            output = root / f"{origin}App"
            run([bazelize, "--input", str(consumer), "--output", str(output)], root)
            target = f"//Packages/{origin}:{origin}"
            if origin == "Local":
                expect_warning_error(["bazel", "--batch", "build", target], output)
            else:
                for mode in ("fastbuild", "opt"):
                    result = run(["bazel", "--batch", "run", "-c", mode, target], output)
                    if result.strip() != "warning dependency executed":
                        raise RuntimeError(f"Unexpected consumer output: {result}")
                print("External: SwiftPM and Bazel consumers execute despite dependency warnings")


if __name__ == "__main__":
    main()
