#!/bin/bash

set -euo pipefail

# A device name has spaces in it, so emit one field per line.
{ read -r device; read -r version; read -r udid; } < <(python3 - <<'PY'
import json
import subprocess


def simctl(*arguments):
    listed = subprocess.run(
        ["xcrun", "simctl", "list", "-j", *arguments],
        capture_output=True,
        check=True,
        text=True,
    )
    return json.loads(listed.stdout)


runtimes = [
    runtime
    for runtime in simctl("runtimes")["runtimes"]
    if runtime["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS")
    and runtime.get("isAvailable")
]
runtimes.sort(key=lambda runtime: [int(part) for part in runtime["version"].split(".")])
runtime = runtimes[-1]

devices = [
    device
    for device in simctl("devices", "available")["devices"].get(runtime["identifier"], [])
    if device["name"].startswith("iPhone")
]
if devices:
    name, udid = devices[-1]["name"], devices[-1]["udid"]
else:
    kinds = [
        kind
        for kind in simctl("devicetypes")["devicetypes"]
        if kind["name"].startswith("iPhone")
    ]
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

echo "Simulator: $device, iOS $version ($udid)"
printf 'SIMULATOR_DEVICE=%s\n' "$device" >> "${GITHUB_ENV:-/dev/null}"
printf 'SIMULATOR_VERSION=%s\n' "$version" >> "${GITHUB_ENV:-/dev/null}"
xcrun simctl boot "$udid" || true
xcrun simctl bootstatus "$udid"
