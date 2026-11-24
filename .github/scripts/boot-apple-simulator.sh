#!/bin/bash

set -euo pipefail

runtime_platform=${1:-iOS}
device_prefix=${2:-iPhone}

# A device name has spaces in it, so emit one field per line. The macOS
# /bin/bash (3.2) parses this heredoc as part of the substitution around it,
# so an unpaired quote in the Python below, even in a comment, breaks the
# script.
{ read -r device; read -r version; read -r udid; } < <(
    python3 - "$runtime_platform" "$device_prefix" <<'PY'
import json
import subprocess
import sys


def simctl(*arguments):
    listed = subprocess.run(
        ["xcrun", "simctl", "list", "-j", *arguments],
        capture_output=True,
        check=True,
        text=True,
    )
    return json.loads(listed.stdout)


platform, prefix = sys.argv[1:]
runtimes = [
    runtime
    for runtime in simctl("runtimes")["runtimes"]
    if runtime.get("platform") == platform and runtime.get("isAvailable")
]
if not runtimes:
    raise RuntimeError(f"no available {platform} Simulator runtime")


def runtime_of_selected_sdk():
    # The rules_apple iOS runner is told a device type and finds the runtime
    # itself: the one the selected Xcode pairs with its SDK. This mirrors that
    # choice, so the device type named to the runner is one its runtime
    # supports. A version cannot name the runtime instead: two runtimes can
    # share a version and support different devices.
    sdk = subprocess.run(
        ["xcrun", "--sdk", "iphoneos", "--show-sdk-version"],
        capture_output=True,
        check=True,
        text=True,
    ).stdout.strip()
    matches = subprocess.run(
        ["xcrun", "simctl", "runtime", "match", "list", "-j"],
        capture_output=True,
        check=True,
        text=True,
    )
    build = json.loads(matches.stdout)[f"iphoneos{sdk}"]["chosenRuntimeBuild"]
    for runtime in runtimes:
        if runtime["buildversion"] == build:
            return runtime
    # The paired build is a preference and may not be installed; the runner
    # then takes the first runtime of the SDK version.
    for runtime in runtimes:
        if runtime["version"] == sdk or runtime["version"].startswith(f"{sdk}."):
            return runtime
    raise RuntimeError(f"no Simulator runtime for the iphoneos{sdk} SDK")


if platform == "iOS":
    runtime = runtime_of_selected_sdk()
else:
    runtimes.sort(key=lambda runtime: [int(part) for part in runtime["version"].split(".")])
    runtime = runtimes[-1]

kinds = {
    kind["identifier"]: kind["name"]
    for kind in runtime["supportedDeviceTypes"]
    if kind["name"].startswith(prefix)
}
if not kinds:
    raise RuntimeError(f"no {prefix} device supports the {runtime['name']} runtime")

# A device the image ships on this runtime says which type to test on; without
# one, the last supported type does.
devices = simctl("devices")["devices"].get(runtime["identifier"], [])
shipped = [
    device["deviceTypeIdentifier"]
    for device in devices
    if device.get("isAvailable")
    and device["name"].startswith(prefix)
    and device.get("deviceTypeIdentifier") in kinds
]
kind = shipped[-1] if shipped else list(kinds)[-1]
device_type = kinds[kind]

# The rules_apple runner reuses a simulator by name alone,
# BAZEL_TEST_<device type>_<runtime version>, the first one on the runtime it
# selected. Any other device, booted or not, is passed over, and the first test
# creates and boots one of its own on its own clock. Booting that very device
# here keeps the boot out of every test.
name = f"BAZEL_TEST_{device_type}_{runtime['version']}"
named = [device for device in devices if device["name"] == name]
if named:
    udid = named[0]["udid"]
else:
    created = subprocess.run(
        [
            "xcrun",
            "simctl",
            "create",
            name,
            kind,
            runtime["identifier"],
        ],
        capture_output=True,
        check=True,
        text=True,
    )
    udid = created.stdout.strip()

print(device_type)
print(runtime["version"])
print(udid)
PY
)

echo "Simulator: $device, $runtime_platform $version ($udid)"
printf 'SIMULATOR_DEVICE=%s\n' "$device" >> "${GITHUB_ENV:-/dev/null}"
printf 'SIMULATOR_UDID=%s\n' "$udid" >> "${GITHUB_ENV:-/dev/null}"

# A fresh image spends minutes migrating data on a runtime's first boot. The
# boot runs in the background so the job's next steps overlap it, and
# wait-apple-simulator.sh waits for it right before the device is needed: the
# device reports `Booted` long before it is ready, and the rules_apple runner
# does not wait on a device in that state. Output goes to a file so the
# background process holds none of this step's pipes.
log="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/simulator-boot-$udid.log"
nohup xcrun simctl bootstatus "$udid" -b > "$log" 2>&1 < /dev/null &
printf 'SIMULATOR_BOOT_LOG=%s\n' "$log" >> "${GITHUB_ENV:-/dev/null}"
echo "Booting in the background; log: $log"
