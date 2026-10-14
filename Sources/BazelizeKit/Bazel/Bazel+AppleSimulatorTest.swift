import Foundation
import PathKit

extension Bazel {
    /// tools/apple_simulator_test.bzl
    ///
    /// rules_apple bundles tvOS, watchOS, and visionOS tests but its runners for
    /// those platforms intentionally exit without running them. This workspace
    /// rule executes the generated bundle through Xcode's supported xctestrun
    /// interface instead.
    struct AppleSimulatorTest: BazelFile {
        init(_ root: Path) {
            path = root + "tools" + "apple_simulator_test.bzl"
        }

        let path: Path

        let code = #"""
        '''Runs an Apple test bundle in its matching simulator.'''

        _RUNNER = r'''#!/usr/bin/env python3

        import json
        import os
        import plistlib
        import re
        import shutil
        import subprocess
        import tempfile
        from pathlib import Path

        DESTINATION_PLATFORM = "%(destination_platform)s"
        DEVELOPER_PLATFORM = "%(developer_platform)s"
        PRODUCT_FAMILY = "%(product_family)s"
        RUNTIME_PLATFORM = "%(runtime_platform)s"
        TEST_BUNDLE = "%(test_bundle_path)s"

        def run(*arguments, capture=False, check=True):
            return subprocess.run(
                arguments,
                capture_output=capture,
                check=check,
                text=True,
            )

        def simctl(*arguments):
            listed = run("xcrun", "simctl", "list", "-j", *arguments, capture=True)
            return json.loads(listed.stdout)

        def version(value):
            return [int(part) for part in value.split(".")]

        runtimes = [
            runtime
            for runtime in simctl("runtimes")["runtimes"]
            if runtime.get("isAvailable") and runtime.get("platform") == RUNTIME_PLATFORM
        ]
        if not runtimes:
            raise RuntimeError(f"no available {RUNTIME_PLATFORM} Simulator runtime")
        runtime = sorted(runtimes, key=lambda item: version(item["version"]))[-1]

        devices = [
            device
            for device in simctl("devices", "available")["devices"].get(runtime["identifier"], [])
            if device.get("isAvailable") and device["name"].startswith(PRODUCT_FAMILY)
        ]
        if devices:
            device = next((item for item in devices if item["state"] == "Booted"), devices[-1])
        else:
            device_types = [
                device_type
                for device_type in runtime["supportedDeviceTypes"]
                if device_type["name"].startswith(PRODUCT_FAMILY)
            ]
            if not device_types:
                raise RuntimeError(
                    f"no {PRODUCT_FAMILY} device supports the {runtime['name']} runtime"
                )
            device_type = device_types[-1]
            created = run(
                "xcrun",
                "simctl",
                "create",
                device_type["name"],
                device_type["identifier"],
                runtime["identifier"],
                capture=True,
            )
            device = {
                "name": device_type["name"],
                "state": "Shutdown",
                "udid": created.stdout.strip(),
            }

        print(f"Simulator: {device['name']}, {runtime['name']} ({device['udid']})")
        if device["state"] != "Booted":
            run("xcrun", "simctl", "boot", device["udid"], check=False)
        run("xcrun", "simctl", "bootstatus", device["udid"], "-b")

        premature_exit = os.environ.get("TEST_PREMATURE_EXIT_FILE")
        if premature_exit:
            Path(premature_exit).touch()

        with tempfile.TemporaryDirectory(prefix="bazel-apple-test-") as temporary:
            root = Path(temporary)
            shutil.unpack_archive(TEST_BUNDLE, root)
            bundles = list(root.glob("*.xctest"))
            if len(bundles) != 1:
                raise RuntimeError(f"expected one .xctest bundle, found {bundles}")
            bundle = bundles[0]
            module_name = bundle.stem.replace("-", "_")

            developer_dir = Path(run("xcode-select", "-p", capture=True).stdout.strip())
            platform_dir = developer_dir / "Platforms" / f"{DEVELOPER_PLATFORM}.platform"
            test_host = platform_dir / "Developer" / "Library" / "Xcode" / "Agents" / "xctest"
            inject = platform_dir / "Developer" / "usr" / "lib" / "libXCTestBundleInject.dylib"

            environment = {
                "DYLD_INSERT_LIBRARIES": str(inject),
                "TEST_SRCDIR": os.environ.get("TEST_SRCDIR", ""),
                "TEST_UNDECLARED_OUTPUTS_DIR": os.environ.get("TEST_UNDECLARED_OUTPUTS_DIR", ""),
                "XML_OUTPUT_FILE": os.environ.get("XML_OUTPUT_FILE", ""),
            }

            target = {
                "DependentProductPaths": [str(bundle)],
                "IsAppHostedTestBundle": False,
                "IsUITestBundle": False,
                "IsXCTRunnerHostedTestBundle": False,
                "ProductModuleName": module_name,
                "TestBundlePath": str(bundle),
                "TestHostPath": str(test_host),
                "TestingEnvironmentVariables": environment,
            }
            test_filter = os.environ.get("TESTBRIDGE_TEST_ONLY", "")
            if test_filter:
                target["OnlyTestIdentifiers"] = [
                    identifier for identifier in test_filter.split(",") if identifier
                ]

            xctestrun = {
                module_name: target,
                "__xctestrun_metadata__": {"FormatVersion": 1},
            }
            xctestrun_path = root / "tests.xctestrun"
            with xctestrun_path.open("wb") as stream:
                plistlib.dump(xctestrun, stream)

            arguments = [
                "xcodebuild",
                "test-without-building",
                "-xctestrun",
                str(xctestrun_path),
                "-destination",
                f"platform={DESTINATION_PLATFORM},id={device['udid']}",
                "-destination-timeout",
                "180",
                "-derivedDataPath",
                str(root / "DerivedData"),
            ]
            outputs = os.environ.get("TEST_UNDECLARED_OUTPUTS_DIR")
            if outputs:
                arguments.extend(["-resultBundlePath", str(Path(outputs) / "tests.xcresult")])

            process = subprocess.Popen(
                arguments,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            executed = False
            assert process.stdout is not None
            for line in process.stdout:
                print(line, end="")
                if re.search(r"Executed [1-9][0-9]* tests?", line) or re.search(
                    r"Test run with [1-9][0-9]* tests?", line
                ):
                    executed = True
            status = process.wait()
            if status:
                raise SystemExit(status)
            if not executed:
                raise RuntimeError("xcodebuild succeeded without executing a test")

        if premature_exit:
            Path(premature_exit).unlink(missing_ok=True)
        '''

        def _apple_simulator_test_impl(ctx):
            executable = ctx.actions.declare_file(ctx.label.name + ".py")
            substitutions = {
                "destination_platform": ctx.attr.destination_platform,
                "developer_platform": ctx.attr.developer_platform,
                "product_family": ctx.attr.product_family,
                "runtime_platform": ctx.attr.runtime_platform,
                "test_bundle_path": ctx.file.bundle.short_path,
            }
            content = _RUNNER
            for key, value in substitutions.items():
                content = content.replace("%(" + key + ")s", value)
            ctx.actions.write(executable, content, is_executable = True)

            return [
                DefaultInfo(
                    executable = executable,
                    runfiles = ctx.runfiles(files = [ctx.file.bundle]),
                ),
                testing.ExecutionInfo({"requires-darwin": ""}),
            ]

        apple_simulator_test = rule(
            implementation = _apple_simulator_test_impl,
            attrs = {
                "bundle": attr.label(
                    allow_single_file = [".zip"],
                    mandatory = True,
                ),
                "destination_platform": attr.string(mandatory = True),
                "developer_platform": attr.string(mandatory = True),
                "product_family": attr.string(mandatory = True),
                "runtime_platform": attr.string(mandatory = True),
            },
            test = True,
        )

        """#
    }
}
