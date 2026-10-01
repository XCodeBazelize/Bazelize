//
//  Plugin+Buildifier.swift
//

// MARK: - PluginBuildifier

/// A generated workspace's own buildifier commands.
///
/// Formatting is buildifier's job rather than the generator's, so a workspace
/// carries the tool to do it: `//:lint` says what is wrong, `//:format` fixes
/// what is only formatting. Neither is run by generation.
final class PluginBuildifier: PluginBuiltin {
    override var name: String { "Buildifier" }

    override func build(_ builder: CodeBuilder) {
        builder.load(loadableRule: Rules.Shell.sh_binary)
        for command in Command.allCases {
            builder.call(
                Rules.Shell.Call.sh_binary(
                    name: command.rawValue,
                    srcs: [command.file]))
        }
    }

    override var custom: [PluginBuiltin.Custom]? {
        Command.allCases.map { command in
            .init(
                path: command.file,
                content: Self.script(
                    buildifier: kit.configuration.buildifier,
                    command: command))
        }
    }

    /// What a generated workspace can do to its own Starlark.
    enum Command: String, CaseIterable {
        /// Report warnings; formatting differences are reported but do not fail.
        case lint
        /// Rewrite the files the way buildifier formats them.
        case format

        var file: String { "\(rawValue).sh" }

        /// What the command does once buildifier is on disk and the files are
        /// collected.
        var body: String {
            switch self {
            case .lint:
                return """
                set +e
                output=$("$buildifier" --mode=check --lint=warn "${files[@]}" 2>&1)
                result=$?
                set -e

                # Check mode returns 4 when formatting differs. Formatting is
                # what `bazel run //:format` is for, so it is reported here
                # rather than failed on.
                if [[ "$result" -ne 0 && "$result" -ne 4 ]]; then
                    printf '%s\\n' "$output" >&2
                    exit "$result"
                fi

                reformat=$(printf '%s\\n' "$output" | grep ' # reformat$' || true)
                if [[ -n "$reformat" ]]; then
                    echo "run bazel run //:format to format:" >&2
                    printf '%s\\n' "$reformat" >&2
                fi

                warnings=$(printf '%s\\n' "$output" | grep -v ' # reformat$' || true)
                if [[ -n "$warnings" ]]; then
                    echo "generated Starlark has buildifier warnings" >&2
                    printf '%s\\n' "$warnings" >&2
                    exit 1
                fi
                """
            case .format:
                return """
                "$buildifier" --mode=fix "${files[@]}"
                echo "formatted ${#files[@]} files"
                """
            }
        }
    }

    private static func script(
        buildifier: BazelizeConfiguration.Buildifier,
        command: Command) -> String
    {
        #"""
    #!/bin/bash
    set -euo pipefail

    version="\#(buildifier.version)"
    host="$(uname -s | tr '[:upper:]' '[:lower:]')/$(uname -m)"
    case "$host" in
    \#(buildifier.hostCases)
        *)
            echo "no buildifier $version is pinned for $host" >&2
            exit 1
            ;;
    esac

    # macOS ships `shasum`, Linux distributions ship `sha256sum`: whichever is
    # there is what verifies the download.
    if command -v shasum >/dev/null 2>&1; then
        verify() { printf '%s  %s\n' "$1" "$2" | shasum -a 256 -c -; }
    else
        verify() { printf '%s  %s\n' "$1" "$2" | sha256sum -c -; }
    fi

    cache="${XDG_CACHE_HOME:-$HOME/.cache}/bazelize/buildifier/$version"
    buildifier="$cache/$asset"
    if [[ ! -x "$buildifier" ]] || \
        ! verify "$sha256" "$buildifier" >/dev/null 2>&1
    then
        mkdir -p "$cache"
        temporary=$(mktemp "$cache/.download.XXXXXX")
        trap 'rm -f "$temporary"' EXIT
        curl -fsSL --retry 3 \
            "https://github.com/bazel-contrib/buildtools/releases/download/v$version/$asset" \
            -o "$temporary"
        verify "$sha256" "$temporary" >/dev/null
        chmod +x "$temporary"
        mv "$temporary" "$buildifier"
        trap - EXIT
    fi

    workspace=${BUILD_WORKSPACE_DIRECTORY:?run this command with bazel run //:\#(command.rawValue)}
    cd "$workspace"

    files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(
        find . -type f \
            \( -name BUILD -o -name WORKSPACE -o -name '*.bzl' -o -name '*.bazel' \) \
            -not -path './.build/*' \
            -not -path './bazel-*' \
            -print0
    )

    if [[ "${#files[@]}" -eq 0 ]]; then
        echo "no generated Starlark files found under $workspace" >&2
        exit 1
    fi

    \#(command.body)

    """#
    }
}
