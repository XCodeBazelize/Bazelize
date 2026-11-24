#!/bin/bash

set -euo pipefail

runtime_platform=${1:-iOS}
device_prefix=${2:-iPhone}

# A device name has spaces in it, so emit one field per line. The macOS
# /bin/bash (3.2) parses this heredoc as part of the substitution around it,
# so an unpaired quote in the Python below, even in a comment, breaks the
# script.
{ read -r device; read -r version; read -r udid; read -r name; read -r ready; } < <(
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
# creates and boots one of its own on its own clock.
#
# The device reports Booted long before it is ready, and the runner does not
# wait on a device in that state. So it boots under another name and takes the
# name the runner reuses only once it is ready: a test that starts before then
# boots its own, and a test served from cache waits for nothing.
name = f"BAZEL_TEST_{device_type}_{runtime['version']}"
hidden = f"{name}_booting"


def rename(udid, to):
    subprocess.run(["xcrun", "simctl", "rename", udid, to], check=True)


ready = [device for device in devices if device["name"] == name]
booting = [device for device in devices if device["name"] == hidden]
if ready and ready[0]["state"] == "Booted":
    udid, state = ready[0]["udid"], "ready"
elif ready:
    udid, state = ready[0]["udid"], "boot"
    rename(udid, hidden)
elif booting:
    udid, state = booting[0]["udid"], "boot"
else:
    created = subprocess.run(
        [
            "xcrun",
            "simctl",
            "create",
            hidden,
            kind,
            runtime["identifier"],
        ],
        capture_output=True,
        check=True,
        text=True,
    )
    udid, state = created.stdout.strip(), "boot"

print(device_type)
print(runtime["version"])
print(udid)
print(name)
print(state)
PY
)

echo "Simulator: $device, $runtime_platform $version ($udid)"
printf 'SIMULATOR_DEVICE=%s\n' "$device" >> "${GITHUB_ENV:-/dev/null}"
printf 'SIMULATOR_UDID=%s\n' "$udid" >> "${GITHUB_ENV:-/dev/null}"
printf 'SIMULATOR_NAME=%s\n' "$name" >> "${GITHUB_ENV:-/dev/null}"

if [ "$ready" = ready ]; then
    echo "$name is already booted"
    exit 0
fi

# A fresh image spends minutes migrating data on a runtime's first boot. The
# boot runs in the background so the job's next steps overlap it. Output goes
# to a file so the background process holds none of this step's pipes.
log="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/simulator-boot-$udid.log"
(
    xcrun simctl bootstatus "$udid" -b &&
        xcrun simctl rename "$udid" "$name" &&
        echo "Ready as $name"
) > "$log" 2>&1 < /dev/null &
printf 'SIMULATOR_BOOT_LOG=%s\n' "$log" >> "${GITHUB_ENV:-/dev/null}"
echo "Booting in the background; log: $log"
