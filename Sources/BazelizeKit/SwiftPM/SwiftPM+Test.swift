//
//  SwiftPM+Test.swift
//
//
//  Rules for the tests of the package that was handed to bazelize.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// A test target of the package handed in becomes a test bundle over a library
    /// of its sources.
    ///
    /// The tests of a package a project merely depends on are not generated:
    /// running them says nothing about the project, and they pull in dependencies
    /// nothing else needs. The tests of the package under the tool are the whole
    /// point of pointing the tool at it.
    ///
    /// It is a bundle rather than a plain `swift_test` because a test target has
    /// resources like any other, and only a bundling rule puts them where
    /// `Bundle.module` looks.
    func buildTest(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        generated: [String],
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        let name = ruleName(of: target.name, in: package)
        let library = "\(name)_library"

        builder.load(loadableRule: Rules.Swift.swift_library)
        builder.call(
            Rules.Swift.Call.swift_library(
                name: library,
                always_include_developer_search_paths: true,
                copts: copts(of: target, in: package),
                module_name: Self.moduleName(target.name),
                package_name: package.manifest.name,
                srcs: sources(
                    naming: resources?.accessors ?? [],
                    globbing: matching(
                        sources(of: target, prefix: prefix, extensions: ["swift"]),
                        relativeFiles(of: target, in: package, prefix: prefix))
                        + generated,
                    excluding: excluded(target, prefix: prefix)),
                deps: deps(of: target, in: package),
                data: resources?.label.map { label in
                    .build { [Starlark.Label.named(label)] }
                },
                linkopts: linkopts(of: target, in: package),
                tags: Self.manual,
                testonly: true,
                visibility: .private))

        builder.load(.ios_unit_test)
        builder.load(.macos_unit_test)
        builder.load(.tvos_unit_test)
        builder.load(loadableRule: Rules.Apple.VisionOS.visionos_unit_test)
        builder.load(.watchos_unit_test)
        builder.load(loadableRule: Rules.Workspace.apple_simulator_test)
        builder.call(
            Rules.Apple.MacOS.Call.macos_unit_test(
                name: name,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "macos"),
                target_compatible_with: ["@platforms//os:macos"],
                visibility: .public))
        builder.call(
            Rules.Apple.IOS.Call.ios_unit_test(
                name: "\(name)_ios_simulator",
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "ios"),
                target_compatible_with: [
                    "@platforms//os:ios",
                    "@apple_support//constraints:simulator",
                ],
                timeout: "long",
                visibility: .public))

        let iOSDeviceConstraints = [
            "@platforms//os:ios",
            "@apple_support//constraints:device",
        ]
        let iOSDeviceRule = "\(name)_ios_device_bundle_rule"
        builder.call(
            Rules.Apple.IOS.Call.ios_unit_test(
                name: iOSDeviceRule,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "ios"),
                tags: Self.manual,
                target_compatible_with: iOSDeviceConstraints,
                visibility: .private))
        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_ios_device_bundle",
                actual: .named(":\(iOSDeviceRule).__internal__.__test_bundle"),
                tags: Self.manual,
                visibility: .public))

        let tvOSConstraints = [
            "@platforms//os:tvos",
            "@apple_support//constraints:simulator",
        ]
        let tvOSBundle = "\(name)_tvos_simulator_bundle"
        builder.call(
            Rules.Apple.TVOS.Call.tvos_unit_test(
                name: tvOSBundle,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "tvos"),
                tags: Self.manual,
                target_compatible_with: tvOSConstraints,
                visibility: .private))
        builder.call(
            Rules.Workspace.Call.apple_simulator_test(
                name: "\(name)_tvos_simulator",
                bundle: .named(":\(tvOSBundle).__internal__.__test_bundle"),
                destination_platform: "tvOS Simulator",
                developer_platform: "AppleTVSimulator",
                product_family: "Apple TV",
                runtime_platform: "tvOS",
                target_compatible_with: tvOSConstraints,
                timeout: "long",
                visibility: .public))

        let tvOSDeviceConstraints = [
            "@platforms//os:tvos",
            "@apple_support//constraints:device",
        ]
        let tvOSDeviceRule = "\(name)_tvos_device_bundle_rule"
        builder.call(
            Rules.Apple.TVOS.Call.tvos_unit_test(
                name: tvOSDeviceRule,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "tvos"),
                tags: Self.manual,
                target_compatible_with: tvOSDeviceConstraints,
                visibility: .private))
        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_tvos_device_bundle",
                actual: .named(":\(tvOSDeviceRule).__internal__.__test_bundle"),
                tags: Self.manual,
                visibility: .public))

        let watchOSConstraints = [
            "@platforms//os:watchos",
            "@apple_support//constraints:simulator",
        ]
        let watchOSBundle = "\(name)_watchos_simulator_bundle"
        builder.call(
            Rules.Apple.WatchOS.Call.watchos_unit_test(
                name: watchOSBundle,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "watchos"),
                tags: Self.manual,
                target_compatible_with: watchOSConstraints,
                visibility: .private))
        builder.call(
            Rules.Workspace.Call.apple_simulator_test(
                name: "\(name)_watchos_simulator",
                bundle: .named(":\(watchOSBundle).__internal__.__test_bundle"),
                destination_platform: "watchOS Simulator",
                developer_platform: "WatchSimulator",
                product_family: "Apple Watch",
                runtime_platform: "watchOS",
                target_compatible_with: watchOSConstraints,
                timeout: "long",
                visibility: .public))

        let watchOSDeviceConstraints = [
            "@platforms//os:watchos",
            "@apple_support//constraints:device",
        ]
        let watchOSDeviceRule = "\(name)_watchos_device_bundle_rule"
        builder.call(
            Rules.Apple.WatchOS.Call.watchos_unit_test(
                name: watchOSDeviceRule,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "watchos"),
                tags: Self.manual,
                target_compatible_with: watchOSDeviceConstraints,
                visibility: .private))
        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_watchos_device_bundle",
                actual: .named(":\(watchOSDeviceRule).__internal__.__test_bundle"),
                tags: Self.manual,
                visibility: .public))

        let visionOSConstraints = [
            "@platforms//os:visionos",
            "@apple_support//constraints:simulator",
        ]
        let visionOSBundle = "\(name)_xros_simulator_bundle"
        builder.call(
            Rules.Apple.VisionOS.Call.visionos_unit_test(
                name: visionOSBundle,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "visionos"),
                tags: Self.manual,
                target_compatible_with: visionOSConstraints,
                visibility: .private))
        builder.call(
            Rules.Workspace.Call.apple_simulator_test(
                name: "\(name)_xros_simulator",
                bundle: .named(":\(visionOSBundle).__internal__.__test_bundle"),
                destination_platform: "visionOS Simulator",
                developer_platform: "XRSimulator",
                product_family: "Apple Vision",
                runtime_platform: "xrOS",
                target_compatible_with: visionOSConstraints,
                timeout: "long",
                visibility: .public))

        let visionOSDeviceConstraints = [
            "@platforms//os:visionos",
            "@apple_support//constraints:device",
        ]
        let visionOSDeviceRule = "\(name)_xros_device_bundle_rule"
        builder.call(
            Rules.Apple.VisionOS.Call.visionos_unit_test(
                name: visionOSDeviceRule,
                deps: .build { [Starlark.Label.named(":\(library)")] },
                minimum_os_version: deployment.required(package, platform: "visionos"),
                tags: Self.manual,
                target_compatible_with: visionOSDeviceConstraints,
                visibility: .private))
        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_xros_device_bundle",
                actual: .named(":\(visionOSDeviceRule).__internal__.__test_bundle"),
                tags: Self.manual,
                visibility: .public))
    }
}
