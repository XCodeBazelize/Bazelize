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
printf 'SIMULATOR_VERSION=%s\n' "$version" >> "${GITHUB_ENV:-/dev/null}"
printf 'SIMULATOR_UDID=%s\n' "$udid" >> "${GITHUB_ENV:-/dev/null}"
xcrun simctl boot "$udid" || true
xcrun simctl bootstatus "$udid"
