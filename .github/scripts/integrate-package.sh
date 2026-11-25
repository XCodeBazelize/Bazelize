#!/bin/bash
# Runs the IntegratePackage checks for SwiftPM fixtures in `spm/`.
#
#   integrate-package.sh                 every fixture in $FIXTURES, a JSON array
#   integrate-package.sh '<fixture>'     one fixture, a JSON object
#
# A fixture object names the package (`name`) and optionally what it is about:
# `programs` (newline-separated `bazel run` arguments), `config` (a trait
# config to test both ways), `traits` (comma-separated), `notes` (the generator
# note it expects, as an extended regex) and `swiftpm` (arguments for `swift
# build` and `swift test`).
#
# Each fixture runs in its own process, so a failing check stops that fixture
# and the next one still runs; any failure fails the whole run. This must stay
# parseable by the macOS /bin/bash (3.2).
set -euo pipefail

root=$PWD

if [ $# -eq 0 ]; then
    : "${FIXTURES:?FIXTURES must be a JSON array of fixtures}"
    summary=${GITHUB_STEP_SUMMARY:-/dev/null}
    echo "| fixture | result | time |" >> "$summary"
    echo "|---|---|---|" >> "$summary"
    failed=""
    count=$(jq length <<< "$FIXTURES")
    index=0
    while [ "$index" -lt "$count" ]; do
        fixture=$(jq -c ".[$index]" <<< "$FIXTURES")
        name=$(jq -r .name <<< "$fixture")
        started=$(date +%s)
        if "$0" "$fixture"; then
            result=passed
        else
            result=failed
            failed="$failed $name"
            echo "::error title=IntegratePackage ($name)::a check of this fixture failed; see its log groups"
        fi
        seconds=$(( $(date +%s) - started ))
        echo "$name $result in ${seconds}s"
        echo "| $name | $result | ${seconds}s |" >> "$summary"
        index=$((index + 1))
    done
    if [ -n "$failed" ]; then
        echo "Failed fixtures:$failed"
        exit 1
    fi
    exit 0
fi

fixture=$1
field() {
    jq -r --arg key "$1" '.[$key] // ""' <<< "$fixture"
}
name=$(field name)
programs=$(field programs)
config=$(field config)
traits=$(field traits)
notes=$(field notes)
swiftpm=$(field swiftpm)

package="$root/spm/$name"
app="$package/App"
# A package that wraps a system library is found through `pkg-config`, and a
# fixture that ships its own `.pc` is only found when that file's directory is
# on the path.
export PKG_CONFIG_PATH="$package/vendor/pkgconfig"

in_group=""
phase() {
    [ -z "$in_group" ] || echo "::endgroup::"
    echo "::group::$name: $1"
    in_group=1
}
trap '[ -z "$in_group" ] || echo "::endgroup::"' EXIT

fail() {
    echo "::error title=IntegratePackage ($name)::$*"
    exit 1
}

# What the fixture holds bazelize to is what SwiftPM does, so what SwiftPM does
# is run too: a fixture whose two sides disagree is a fixture that proves
# nothing.
#
# Every package of the fixture, not only the one bazelize is pointed at: the
# packages beside it are dependencies with sources of their own, and one that
# stopped building would be found here rather than in whatever it broke. A
# package with no tests is built and not run (there is nothing to run) and
# `App/` is generated, not a package of the fixture. A package that is only a
# plugin has nothing to build either: SwiftPM refuses the build rather than
# doing nothing, so it is skipped by what its manifest declares.
#
# Which packages those are is read from the manifest rather than the directory
# tree: a test target names its own `path`, so `Tests/` being absent says
# nothing about whether there are tests to run.
# `swiftpm` holds several arguments, so it is split on purpose here.
# shellcheck disable=SC2086
swiftpm_build_and_test() {
    local status=0 manifest member model
    while read -r manifest; do
        member=$(dirname "$manifest")
        phase "SwiftPM $member"
        # One manifest answers both questions: whether anything here is built,
        # and whether a test target exists wherever its `path` put it.
        if ! model=$(cd "$package/$member" && swift package dump-package); then
            echo "::error::swift package dump-package failed for $name/$member"
            status=1
        elif ! jq -e '[.targets[] | select(.type != "plugin")] | length > 0' <<< "$model" > /dev/null; then
            echo "only plugins here, nothing to build"
        elif ! (cd "$package/$member" && swift build $swiftpm); then
            echo "::error::swift build failed for $name/$member"
            status=1
        elif jq -e '[.targets[] | select(.type == "test")] | length > 0' <<< "$model" > /dev/null &&
            ! (cd "$package/$member" && swift test $swiftpm); then
            echo "::error::swift test failed for $name/$member"
            status=1
        fi
    done < <(cd "$package" && find . -name Package.swift -not -path "*/App/*" -not -path "*/.build/*" | sort)
    [ "$status" -eq 0 ] || fail "SwiftPM build or test failed"
}

if [ "$name" = RegistryPackage ]; then
    phase "Seed offline registry download"
    mkdir -p "$app/.build/registry/downloads"
    cp -R "$package/Registry/." "$app/.build/registry/downloads/"
else
    swiftpm_build_and_test
fi

# A note is the generator saying the build differs from what the package asked
# for: a plugin that did not run, a program whose resources nothing can bundle,
# a library pkg-config has never heard of. Every one of those builds and tests
# green and is wrong at run time, so no fixture may produce one silently: a
# fixture expecting a note names it in `notes`, and anything else said is a
# failure.
phase "Bazel generation"
log="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/bazelize-$name.log"
chmod +x "$root/bazelize"
"$root/bazelize" --input "spm/$name" --output "spm/$name/App" | tee "$log"
if [ -n "$notes" ]; then
    grep -qE "$notes" "$log" || fail "the note this fixture is here for was not said: $notes"
elif [ -s "$log" ]; then
    fail "the generator said something no fixture expects"
fi

phase "Check generated Starlark"
(cd "$app" && bash "$root/.github/scripts/check-generated-starlark.sh")

if [ "$name" = SwiftSettings ]; then
    phase "Check package warning policy"
    python3 "$root/.github/scripts/check-package-warnings.py" "$root/bazelize"
fi

# Nothing runs the plugins here: generation ends with `bazel run //:plugins`,
# so a target whose sources a plugin generates compiles in the package test
# below, or the generator failed to run them and said so.

# The workspace's own commands, which answer whatever the package is: a package
# with no trait, no configuration and no localization answers that.
phase "List workspace"
(
    cd "$app"
    PATH="$root:$PATH" bazel list config
    PATH="$root:$PATH" bazel list trait
    PATH="$root:$PATH" bazel list language
)

cd "$app"

# A build that names a localization bundles that one and `Base`, and nothing
# else. What is in the bundle is the only proof of that.
if [ "$name" = TargetResource ]; then
    phase "Filter localizations"
    bazel build //Packages/TargetResource:TargetResourceTests --config=lang.en
    bundle=$(find -L bazel-bin/Packages/TargetResource -name TargetResourceTests.zip | head -1)
    entries=$(unzip -Z1 "$bundle")
    grep -q "en.lproj" <<< "$entries" || fail "en.lproj is missing from the lang.en bundle"
    grep -q "Base.lproj" <<< "$entries" || fail "Base.lproj is missing from the lang.en bundle"
    if grep -q "ja.lproj" <<< "$entries"; then fail "ja.lproj is in the lang.en bundle"; fi
    if grep -q "de.lproj" <<< "$entries"; then fail "de.lproj is in the lang.en bundle"; fi
fi

# The subprocess runtime needs macOS 13 while the consumer may target 12.
# Building only the host isolates this from the fixture plugin's own APIs.
if [ "$name" = PrebuildPlugin ]; then
    phase "Build plugin host for older consumer"
    bazel build //:_plugin_host --macos_minimum_os=12.0
fi

# A command plugin is not run by a build: it is a verb someone types, and
# running it is the only proof it is there. The fixture also has an executable
# product named `hello`, so the command target is disambiguated as
# `hello_command`.
if [ "$name" = CommandPlugin ]; then
    phase "Run command plugin"
    bazel run //Packages/CommandPlugin:hello_command -- alpha --beta > command.log
    grep -q "Hello from CommandPlugin" command.log || fail "the command plugin did not greet"
    grep -q "Arguments: alpha --beta" command.log || fail "the command plugin did not receive its arguments"
fi

# `bazel test` treats an empty wildcard as an error. Executable-only and
# library-only fixtures still build above; ask Bazel whether there is anything
# to run instead of inventing a no-op test.
phase "Test package"
tests=$(bazel query 'tests(//...)')
if [ -n "$tests" ]; then
    bazel test //...
else
    echo "no Bazel tests, nothing to test"
fi

if [ "$name" = ConfigurationCondition ]; then
    phase "Test release configuration"
    (cd "$package" && swift test -c release)
    bazel test -c opt //...
    actions=$(bazel aquery -c opt 'mnemonic("SwiftCompile", deps(//Packages/ConfigurationCondition:ConfigurationCondition))')
    grep -q -- '-DRELEASE_ONLY' <<< "$actions" || fail "-DRELEASE_ONLY is missing from the optimized compile"
    if grep -q -- '-DDEBUG_ONLY' <<< "$actions"; then fail "-DDEBUG_ONLY reached the optimized compile"; fi
fi

# A test bundle carries its own `minimum_os_version` through the rule's
# platform transition, so it proves nothing about the floor every other compile
# gets. Building the library on its own is what reads the default the workspace
# wrote, and the back-port it compiles is `obsoleted:` above the package's
# floor.
if [ "$name" = DeploymentFloor ]; then
    phase "Build package at its deployment floor"
    grep -q 'build --macos_minimum_os=13.0' config.bazelrc || fail "config.bazelrc does not set the deployment floor"
    bazel build //Packages/DeploymentFloor:FloorProbe
fi

# SwiftPM's macOS resource bundle is wrapped in Contents/Resources while
# apple_resource_bundle is flat. Compare their logical resource roots, and
# require every other observed difference to stay in the documented baseline.
if [ "$name" = TargetResource ]; then
    phase "Compare resource bundles"
    bazel build //Packages/TargetResource:TargetResourceTests
    output=$(bazel cquery //Packages/TargetResource:TargetResourceTests --output=files | grep 'TargetResourceTests.zip$')
    archive="$(bazel info execution_root)/$output"
    generated="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/target-resource-bundles"
    rm -rf "$generated"
    unzip -q "$archive" -d "$generated"
    for bundle_name in TargetResource_TargetResource.bundle TargetResource_TargetResourceTests.bundle; do
        reference=$(find -L "$package/.build" -type d -name "$bundle_name" -not -path '*.xctest/*' -print -quit)
        "$root/.github/scripts/compare-bundles.py" \
            --reference "$reference" \
            --generated "$generated/TargetResourceTests.xctest/Contents/Resources/$bundle_name" \
            --swiftpm-resource \
            --baseline "$root/.github/scripts/bundle-differences.json"
    done
fi

# One generated library is compiled through two platform configurations: each
# gets its own settings and only iOS gets the conditional target. Optimized iOS
# keeps the platform condition but drops the debug half of a combined
# condition.
if [ "$name" = Platform ]; then
    phase "Test platform conditions"
    bazel build //Packages/Platform:Platform --platforms=@apple_support//platforms:ios_sim_arm64
    query='mnemonic("SwiftCompile", deps(//Packages/Platform:Platform))'
    mac=$(bazel aquery "$query")
    ios=$(bazel aquery --platforms=@apple_support//platforms:ios_sim_arm64 "$query")
    ios_opt=$(bazel aquery -c opt --platforms=@apple_support//platforms:ios_sim_arm64 "$query")

    grep -q -- '-DMACOS_PLATFORM' <<< "$mac" || fail "macOS compile lacks -DMACOS_PLATFORM"
    if grep -q -- '-DIOS_PLATFORM' <<< "$mac"; then fail "macOS compile has -DIOS_PLATFORM"; fi
    if grep -q 'Sources/IOSOnly/IOSOnly.swift' <<< "$mac"; then fail "macOS compile includes the iOS-only target"; fi

    grep -q -- '-DIOS_PLATFORM' <<< "$ios" || fail "iOS compile lacks -DIOS_PLATFORM"
    grep -q -- '-DIOS_DEBUG' <<< "$ios" || fail "debug iOS compile lacks -DIOS_DEBUG"
    if grep -q -- '-DMACOS_PLATFORM' <<< "$ios"; then fail "iOS compile has -DMACOS_PLATFORM"; fi
    grep -q 'Sources/IOSOnly/IOSOnly.swift' <<< "$ios" || fail "iOS compile lacks the iOS-only target"

    grep -q -- '-DIOS_PLATFORM' <<< "$ios_opt" || fail "optimized iOS compile lacks -DIOS_PLATFORM"
    if grep -q -- '-DIOS_DEBUG' <<< "$ios_opt"; then fail "optimized iOS compile has -DIOS_DEBUG"; fi
fi

# A program is not a test: the rules that build one carry `manual`, so `//...`
# never builds it. Running it is what says it links and works.
if [ -n "$programs" ]; then
    phase "Run package programs"
    while read -r program; do
        [ -n "$program" ] || continue
        # The arguments after the label are split as written.
        # shellcheck disable=SC2086
        bazel run $program < /dev/null
    done <<< "$programs"
fi

# Both ways round, and not only that both pass: a trait is a compilation
# condition named after itself, so the flag reaching swiftc is the thing to see.
if [ -n "$config" ]; then
    phase "Test package with trait"
    bazel test //... "--config=$config"
    flag="-D${config#*.}"
    # Into a variable first: under pipefail, `aquery | grep -q` fails with the
    # SIGPIPE aquery gets when grep stops reading at its first match.
    without=$(bazel aquery 'mnemonic("SwiftCompile", //...)')
    with=$(bazel aquery "--config=$config" 'mnemonic("SwiftCompile", //...)')
    if grep -q -- "$flag" <<< "$without"; then
        fail "$flag reached a compile without --config=$config"
    fi
    grep -q -- "$flag" <<< "$with" || fail "$flag is missing with --config=$config"
fi

# Select each declared trait on its own, through the `--config` the workspace
# generated for it. That is what `swift test --traits <trait>` does: the
# selection replaces the package's defaults, and carries whatever that trait
# enables.
if [ -n "$traits" ]; then
    phase "Test each package trait"
    IFS=',' read -ra selected <<< "$traits"
    for trait in "${selected[@]}"; do
        bazel test //... "--config=$name.$trait"
    done
fi

# What each selection resolves to, exactly: the closure of the trait asked
# for, and nothing of the defaults it replaced. The three SwiftPM names rather
# than lists (`--disable-default-traits`, `--enable-all-traits`, `--traits
# default`) answer the same here.
if [ "$name" = TraitGraph ]; then
    phase "Probe trait selections"
    bazel run //Packages/TraitGraph:TraitProbe -- Leaf Middle Top
    bazel run //Packages/TraitGraph:TraitProbe --config=TraitGraph.Middle -- Leaf Middle
    bazel run //Packages/TraitGraph:TraitProbe --config=TraitGraph.Alternative -- Alternative
    bazel run //Packages/TraitGraph:TraitProbe --config=TraitGraph.none
    bazel run //Packages/TraitGraph:TraitProbe --config=TraitGraph.all -- Alternative Leaf Middle Top
    bazel run //Packages/TraitGraph:TraitProbe --config=TraitGraph.default -- Leaf Middle Top
fi
