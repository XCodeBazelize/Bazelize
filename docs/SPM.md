## workspace

```bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "cgrindel_rules_spm",
    sha256 = "ba4310ba33cd1864a95e41d1ceceaa057e56ebbe311f74105774d526d68e2a0d",
    strip_prefix = "rules_spm-0.10.0",
    urls = [
        "http://github.com/cgrindel/rules_spm/archive/v0.10.0.tar.gz",
    ],
)

load(
    "@cgrindel_rules_spm//spm:deps.bzl",
    "spm_rules_dependencies",
)

spm_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()
```

## Workspace

```bazel
load("@cgrindel_rules_spm//spm:defs.bzl", "spm_pkg", "spm_repositories")

spm_repositories(
    name = "swift_pkgs",
    dependencies = [
        spm_pkg(
            "https://github.com/apple/swift-log.git",
            exact_version = "1.4.2",
            products = ["Logging"],
        ),
    ],
)
```

## import

```bazel
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "simple",
    srcs = ["main.swift"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        "@swift_pkgs//swift-log:Logging",
    ],
)
```
