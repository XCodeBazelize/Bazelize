#!/bin/bash

set -euo pipefail

runtime_platform=${1:-iOS}
device_prefix=${2:-iPhone}
fresh=${3:-}

# A device name has spaces in it, so emit one field per line.
{ read -r device; read -r version; read -r udid; } < <(
    python3 - "$runtime_platform" "$device_prefix" "$fresh" <<'PY'
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


platform, prefix, fresh = sys.argv[1:]
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

devices = [
    device
    for device in simctl("devices", "available")["devices"].get(runtime["identifier"], [])
    if device.get("isAvailable") and device["name"].startswith(prefix)
]
if devices and not fresh:
    name, udid = devices[-1]["name"], devices[-1]["udid"]
else:
    kinds = [
        kind
        for kind in runtime["supportedDeviceTypes"]
        if kind["name"].startswith(prefix)
    ]
    if not kinds:
        raise RuntimeError(f"no {prefix} device supports the {runtime['name']} runtime")
    name = kinds[-1]["name"]
    created = subprocess.run(
        [
            "xcrun",
            "simctl",
            "create",
            name,
            kinds[-1]["identifier"],
            runtime["identifier"],
        ],
        capture_output=True,
        check=True,
        text=True,
    )
    udid = created.stdout.strip()

print(name)
print(runtime["version"])
print(udid)
PY
)

echo "Simulator: $device, $runtime_platform $version ($udid)"
printf 'SIMULATOR_DEVICE=%s\n' "$device" >> "${GITHUB_ENV:-/dev/null}"
printf 'SIMULATOR_UDID=%s\n' "$udid" >> "${GITHUB_ENV:-/dev/null}"
xcrun simctl boot "$udid" || true
xcrun simctl bootstatus "$udid"
