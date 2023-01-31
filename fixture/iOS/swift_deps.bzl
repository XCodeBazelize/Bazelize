load("@cgrindel_swift_bazel//swiftpkg:defs.bzl", "local_swift_package", "swift_package")

# Contents of swift_deps.bzl
def swift_dependencies():
    local_swift_package(
        name = "swiftpkg_local1",
        dependencies_index = "@//:swift_deps_index.json",
        path = "Local1",
    )

    # version: 0.6.7
    swift_package(
        name = "swiftpkg_anycodable",
        commit = "862808b2070cd908cb04f9aafe7de83d35f81b05",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/Flight-School/AnyCodable",
    )

    # version: 6.5.0
    swift_package(
        name = "swiftpkg_rxswift",
        commit = "b4307ba0b6425c0ba4178e138799946c3da594f8",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/ReactiveX/RxSwift",
    )
