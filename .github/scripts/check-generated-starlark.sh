#!/bin/bash
set -euo pipefail

# Called from an already-generated workspace; no second resolution or plugin run.
if ! bazel run //:lint; then
    echo "::warning title=Generated Starlark lint::$PWD has non-blocking buildifier warnings"
fi
bazel run //:lint-ci
