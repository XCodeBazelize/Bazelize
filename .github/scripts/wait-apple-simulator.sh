#!/bin/bash

set -euo pipefail

# Waits for the boot boot-apple-simulator.sh started in the background.
udid=${SIMULATOR_UDID:?boot-apple-simulator.sh did not run}
started=$(date +%s)

state() {
    xcrun simctl list devices -j | python3 -c '
import json, sys
udid = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["udid"] == udid:
            print(device["state"])
' "$udid"
}

status=0
# `-b` boots the device if the background boot never got it there. It refuses
# a device another boot already moved out of `Shutdown`; that boot is then
# waited for instead. A device still `Shutdown` after a refusal is a real
# failure, and waiting on it would never end.
if ! xcrun simctl bootstatus "$udid" -b; then
    case "$(state)" in
        Booting | Booted) xcrun simctl bootstatus "$udid" || status=$? ;;
        *) status=1 ;;
    esac
fi

if [ -n "${SIMULATOR_BOOT_LOG:-}" ] && [ -f "$SIMULATOR_BOOT_LOG" ]; then
    echo "::group::Background boot log"
    tail -n 20 "$SIMULATOR_BOOT_LOG"
    echo "::endgroup::"
fi
echo "Waited $(( $(date +%s) - started ))s for $udid ($(state))"
exit "$status"
