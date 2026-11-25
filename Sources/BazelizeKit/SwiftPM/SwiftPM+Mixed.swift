//
//  SwiftPM+Mixed.swift
//
//
//  Rules for a package target written in Swift and in C, Objective-C or C++.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// Whether a target is one module written in both languages: Swift beside
    /// C-family sources, or beside the public headers of a C-family interface.
    ///
    /// SwiftPM 6.5 builds such a target as one module that a consumer imports
    /// once, and so does the rule a mixed target becomes. An older manifest
    /// cannot declare one: there SwiftPM ignores headers beside Swift and
    /// rejects C-family sources, so nothing about such a target changes.
    func isMixed(_ target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Bool {
        let tools = package.manifest.toolsVersion.split(separator: ".").map { Int($0) ?? 0 }
        guard !tools.lexicographicallyPrecedes([6, 5]) else { return false }

        let extensions = extensions(of: target, in: package)
        guard extensions.contains("swift") else { return false }
        guard Self.compileExtensions.allSatisfy({ !extensions.contains($0) }) else { return true }

        guard
            let directory = sourceDirectory(of: target, in: package),
            let headers = publicHeaders(of: target, in: directory)
        else {
            return false
        }

        return Self.walk(directory + headers).contains { file in
            file.extension.map { Self.headerExtensions.contains($0) } ?? false
        }
    }

    /// A mixed target becomes a `mixed_language_library`: the one rule rules_swift
    /// offers that is a single Swift module with a Clang module under it, so
    /// `import Target` reaches the Swift API and the C-family one alike, and the
    /// C-family sources see the Swift API through `Target-Swift.h`.
    ///
    /// `name` and `testonly` are for a test target, whose library is the same
    /// rule over the same files.
    func buildMixed(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        root: Path,
        generated: PluginGenerated,
        resources: ResourceBundle?,
        name library: String? = nil,
        testonly: Bool = false,
        builder: CodeBuilder)
    {
        guard let directory = sourceDirectory(of: target, in: package) else { return }

        let extensions = extensions(of: target, in: package)
        let compiled = Self.compileExtensions.filter { extensions.contains($0) }
        let headers = publicHeaders(of: target, in: directory)
        let onDisk = relativeFiles(of: target, in: package, prefix: prefix, excluding: false)
        let headerPrefix = headers.map { Self.path(prefix, $0) }

        /// What a plugin wrote splits by language, the way the files of the
        /// target itself do. Headers go with the C-family half.
        let swiftGenerated = generated.sources.filter { $0.hasSuffix(".swift") }
        let clangGenerated = generated.sources.filter { !$0.hasSuffix(".swift") } + generated.headers
        let accessors = resources?.accessors ?? []
        let swiftAccessors = accessors.filter { $0.hasSuffix(".swift") }
        let clangAccessors = accessors.filter { !$0.hasSuffix(".swift") }

        /// The package's own module map, when it ships one, is the interface it
        /// intends; without one the rule writes a map from the public headers.
        let module = Self.moduleName(target.name)
        let interface = try? mirror(
            headersOf: target,
            at: headers.map { directory + $0 },
            module: module,
            generatingMap: false,
            root: root)
        let shippedMap = interface.flatMap { path -> String? in
            (root + path + "module.modulemap").exists ? "\(path)/module.modulemap" : nil
        }

        let bridging = bridgingHeaders(of: target, in: package, prefix: prefix)
        let clangImportOptions = grouped(target.settings, in: package, always: []) { setting in
            Self.clangFlags(setting).flatMap { ["-Xcc", $0] }
        }
        let interfaceHeaders = interface.map { path in
            matching(
                Self.headerExtensions.map { "\(path)/**/*.\($0)" },
                Self.relativeFiles(under: path, in: root))
        } ?? []

        /// The module under its own name, and once more under each name a
        /// consumer aliased it to.
        for alias in [target.name] + aliases(of: target.name, in: package) {
            let isAlias = alias != target.name
            let aliased = Self.moduleName(alias)

            builder.load(loadableRule: Rules.Swift.mixed_language_library)
            builder.call(
                Rules.Swift.Call.mixed_language_library(
                    name: library.map { isAlias ? Self.aliasRuleName(of: $0, as: alias) : $0 }
                        ?? (isAlias
                            ? Self.aliasRuleName(of: target.name, as: alias)
                            : ruleName(of: target.name, in: package)),
                    alwayslink: true,
                    clang_copts: clangCopts(
                        of: target,
                        in: package,
                        module: aliased,
                        compiled: compiled,
                        resources: resources),
                    clang_srcs: sources(
                        naming: clangAccessors,
                        globbing: matching(
                            sources(of: target, prefix: prefix, extensions: compiled)
                                + Self.headerExtensions.map { "\(prefix)/**/*.\($0)" },
                            onDisk)
                            + clangGenerated,
                        excluding: excludedClang(target, prefix: prefix)
                            + (headerPrefix.map { $0 == prefix ? [] : ["\($0)/**"] } ?? [])),
                    data: resources?.labels.nonEmpty.map { labels in
                        .build { labels.map { Starlark.Label.named($0) } }
                    },
                    enable_modules: true,
                    /// The extended module map is named `module.modulemap` and put
                    /// on the include path, so a C-family dependent's `@import`
                    /// finds both halves the way SwiftPM's generated map offers them.
                    features: ["swift.propagate_generated_module_map"],
                    hdrs: (interfaceHeaders + bridging.visible).nonEmpty.map { files(matching: $0) },
                    includes: includes(
                        of: target,
                        prefix: prefix,
                        interface: interface).nonEmpty,
                    linkopts: linkopts(of: target, in: package),
                    module_map: shippedMap.map { .named($0) },
                    module_name: aliased,
                    package_name: package.manifest.name,
                    swift_copts: .concat([
                        copts(
                            of: target,
                            in: package,
                            extra: bridging.hidden.flatMap {
                                ["-internal-import-bridging-header", "$(execpath \($0))"]
                            }),
                        clangImportOptions,
                    ].compactMap { $0 }),
                    swift_plugins: plugins(of: target, in: package),
                    swift_srcs: sources(
                        naming: swiftAccessors,
                        globbing: matching(
                            sources(of: target, prefix: prefix, extensions: ["swift"]),
                            relativeFiles(of: target, in: package, prefix: prefix))
                            + swiftGenerated,
                        excluding: excluded(target, prefix: prefix)),
                    swiftc_inputs: bridging.hidden.nonEmpty.map { files(matching: $0) },
                    tags: Self.manual,
                    testonly: testonly ? true : nil,
                    deps: deps(of: target, in: package),
                    visibility: testonly ? .private : .public))
        }
    }

    /// `.bridgingHeader(_:visibility:)`: a header that is neither beside the
    /// public ones nor listed anywhere else.
    ///
    /// A public one is part of the module's C-family interface, so it travels
    /// with the public headers; an internal one is only what the module's own
    /// Swift is compiled against.
    private func bridgingHeaders(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String)
        -> (visible: [String], hidden: [String])
    {
        var visible: [String] = []
        var hidden: [String] = []

        for setting in target.settings where setting.tool == "swift" && setting.name == "bridgingHeader" {
            guard let header = setting.values.first else { continue }

            /// A bridging header that depends on the platform or the
            /// configuration would have to be a `select` over a file; the one
            /// that applies cannot be known here.
            guard setting.condition == nil else {
                note("""
                \(package.directory)/\(target.name) sets bridgingHeader(\(header)) under a \
                condition: a conditional bridging header is not generated.
                """)
                continue
            }

            let path = Self.path(prefix, header)
            if setting.values.dropFirst().first == "public" {
                visible.append(path)
            } else {
                hidden.append(path)
            }
        }

        return (visible, hidden)
    }
}
