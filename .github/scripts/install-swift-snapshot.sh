#!/bin/bash
set -euo pipefail

# Installs the pinned official Swift snapshot for the current user and exposes
# it to the steps that follow: `swift` first on PATH for SwiftPM, and
# TOOLCHAINS for Bazel, which the workspace passes on through user.bazelrc.
snapshot=swift-DEVELOPMENT-SNAPSHOT-2026-11-01-a
identifier=org.swift.65202611011a
url=https://download.swift.org/development/xcode/$snapshot/$snapshot-osx.pkg
toolchain=$HOME/Library/Developer/Toolchains/$snapshot.xctoolchain

pkg=$RUNNER_TEMP/$snapshot.pkg
curl --fail --location --silent --show-error --output "$pkg" "$url"
pkgutil --check-signature "$pkg"
installer -pkg "$pkg" -target CurrentUserHomeDirectory
rm -f "$pkg"

PATH=$toolchain/usr/bin:$PATH
swift --version
swift --version | grep -q 'Swift version 6.5'

{
    echo "TOOLCHAINS=$identifier"
    echo "SWIFT_TOOLCHAIN=$toolchain"
} >> "$GITHUB_ENV"
echo "$toolchain/usr/bin" >> "$GITHUB_PATH"
