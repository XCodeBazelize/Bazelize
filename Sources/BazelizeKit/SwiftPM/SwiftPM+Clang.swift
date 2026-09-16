//
//  SwiftPM+Clang.swift
//
//
//  Rules for a package target written in C, Objective-C or C++.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// A C-family target becomes an `objc_library`: the same rule an Xcode target
    /// with C sources uses, so headers, includes and defines behave identically on
    /// both sides of the graph.
    func buildClang(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        root: Path,
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        guard let directory = sourceDirectory(of: target, in: package) else { return }

        let module = Self.moduleName(target.name)
        let imported = moduleMaps(of: target, in: package)
        let extensions = extensions(of: target, in: package)
        let headers = publicHeaders(of: target, in: directory)
        let compiled = Self.compileExtensions.filter { extensions.contains($0) }
        /// Headers are matched against everything on disk: `exclude` can drop a
        /// directory that a header search path still points into.
        let files = relativeFiles(of: target, in: package, prefix: prefix, excluding: false)

        /// The hint is what names the module: without it the module is named after
        /// the label, and a Swift `import` of the target's own name fails. A module
        /// map the package wrote itself replaces the generated one, because it is
        /// the interface the package intends.
        let name = ruleName(of: target.name, in: package)
        let hint = "\(name)_interop"
        let headerPrefix = headers.map { Self.path(prefix, $0) }
        let moduleMap = try? write(
            moduleMapOf: target,
            in: package,
            headers: headerPrefix,
            root: root)

        builder.load(loadableRule: Rules.Swift.swift_interop_hint)
        builder.call(
            Rules.Swift.Call.swift_interop_hint(
                name: hint,
                module_map: moduleMap.map { .named($0) },
                module_name: module))

        builder.load(loadableRule: Rules.Objc.objc_library)
        builder.call(
            Rules.Objc.Call.objc_library(
                name: name,
                aspect_hints: .build { [Starlark.Label.named(":\(hint)")] },
                srcs: Starlark.glob(
                    matching(
                        sources(of: target, prefix: prefix, extensions: compiled)
                            /// Private headers are compilation inputs wherever they
                            /// sit, so they are collected from the whole directory
                            /// even when the sources are listed one by one.
                            + (headerPrefix == prefix
                                ? []
                                : Self.headerExtensions.map { "\(prefix)/**/*.\($0)" }),
                        files)
                        + (resources?.accessors ?? []),
                    exclude: excludedClang(target, prefix: prefix)
                        + (headerPrefix.map { $0 == prefix ? [] : ["\($0)/**"] } ?? [])),
                hdrs: headerPrefix
                    .map { path in
                        matching(Self.headerExtensions.map { "\(path)/**/*.\($0)" }, files)
                    }?
                    .nonEmpty
                    .map { Starlark.glob($0) },
                deps: deps(of: target, in: package).nonEmpty.map { labels in
                    .build { labels }
                },
                data: resources.map { bundle in
                    .build { [Starlark.Label.named(bundle.label)] }
                },
                alwayslink: true,
                copts: clangCopts(
                    of: target,
                    in: package,
                    module: module,
                    resources: resources).nonEmpty,
                enable_modules: true,
                includes: includes(of: target, prefix: prefix, headers: headers).nonEmpty,
                linkopts: linkopts(of: target).nonEmpty,
                /// The module a dependent's `@import` names: the package target's
                /// own name, not the one Bazel derives from the label.
                module_name: module,
                tags: Self.manual,
                /// A dependency's module map is what makes its `@import` resolve;
                /// a C-family consumer, unlike a Swift one, gets none from the
                /// rules.
                textual_hdrs: imported.nonEmpty.map { maps in
                    .build { maps.map { Starlark.Label.named($0.label) } }
                },
                visibility: .public))
    }

    /// The target's own module map: the one the package ships, or one written
    /// here over its public headers.
    ///
    /// SwiftPM writes one for a clang target that ships none, and the map is
    /// what both a Swift `import` and a C-family `@import` of this target
    /// resolve through.
    private func write(
        moduleMapOf target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        headers: String?,
        root: Path) throws -> String?
    {
        guard let map = module(of: target.name, in: package) else { return nil }

        let relative = map.label.split(separator: ":").last.map(String.init) ?? ""
        guard relative.hasPrefix("Generated/") else { return relative }
        guard let headers else { return nil }

        try (root + "Generated").mkpath()
        try (root + relative).write("""
        module \(Self.moduleName(target.name)) {
            umbrella "../\(headers)"
            export *
        }

        """)

        return relative
    }

    /// What `exclude` removes from a C-family target.
    ///
    /// A directory that is also a header search path keeps its headers: they are
    /// compilation inputs reached by `-I`, and excluding them leaves the compiler
    /// looking for a file the sandbox does not have. Only what would be compiled
    /// from there is dropped.
    private func excludedClang(_ target: SwiftPM.PackageTarget, prefix: String) -> [String] {
        let searched = Set(target.settings.flatMap { setting -> [String] in
            guard setting.tool == "c" || setting.tool == "cxx" else { return [] }
            guard setting.name == "headerSearchPath" else { return [] }
            return setting.values.map { Path($0).normalize().string }
        })

        return target.exclude.flatMap { excluded -> [String] in
            let path = Path(excluded).normalize().string

            if searched.contains(path) {
                return Self.compileExtensions.map { "\(prefix)/\(path)/**/*.\($0)" }
            }
            return Path(excluded).extension == nil
                ? ["\(prefix)/\(excluded)/**"]
                : ["\(prefix)/\(excluded)"]
        } + Self.ignoredExtensions.map { "\(prefix)/**/*.\($0)/**" }
    }

    /// `publicHeadersPath`, defaulting to the `include` directory SwiftPM looks
    /// for. It can also be `.`, meaning the target's own directory.
    func publicHeaders(of target: SwiftPM.PackageTarget, in directory: Path) -> String? {
        let path = target.publicHeadersPath ?? "include"
        return (directory + path).isDirectory ? path : nil
    }

    /// A path a glob accepts: no `.` segment survives normalization.
    static func path(_ prefix: String, _ path: String) -> String {
        Path("\(prefix)/\(path)").normalize().string
    }

    /// What a header lookup can reach: the public headers, the target directory
    /// itself — a target's own sources include each other by relative path — and
    /// whatever `headerSearchPath` adds.
    private func includes(
        of target: SwiftPM.PackageTarget,
        prefix: String,
        headers: String?) -> [String]
    {
        var paths = [prefix]
        if let headers {
            paths.append(Self.path(prefix, headers))
        }

        for setting in target.settings
            where setting.tool == "c" && setting.name == "headerSearchPath"
        {
            paths.append(contentsOf: setting.values.map { Self.path(prefix, $0) })
        }

        return NSOrderedSet(array: paths).compactMap { $0 as? String }
    }

    /// The module name has to be stated: without it clang names the module after
    /// the module map's directory, and a Swift `import` of the target fails.
    private func clangCopts(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        module: String,
        resources: ResourceBundle?) -> [String]
    {
        var copts = ["-fmodule-name=\(module)"] + clangDefines(of: target)

        /// The module map of each dependency, so its `@import` resolves.
        for map in moduleMaps(of: target, in: package) {
            copts.append("-fmodule-map-file=\(map.path)")
        }

        /// SwiftPM force-includes the accessor, so a source reaches its bundle
        /// without importing anything.
        if let header = resources?.header {
            copts.append("-include$(location \(header))")
        }

        if let standard = package.manifest.cLanguageStandard {
            copts.append("-std=\(standard)")
        }
        if let standard = package.manifest.cxxLanguageStandard {
            copts.append("-std=\(standard)")
        }

        for setting in target.settings where setting.tool == "c" || setting.tool == "cxx" {
            guard setting.name == "unsafeFlags" else { continue }
            copts.append(contentsOf: setting.values)
        }

        return copts
    }
}

extension SwiftPM.Generator {
    /// `c.define` and `cxx.define`, plus the `SWIFT_PACKAGE` every package target
    /// compiles with.
    ///
    /// Flags, not the `defines` attribute, for the same reason as a Swift target:
    /// the attribute would propagate into everything downstream.
    func clangDefines(of target: SwiftPM.PackageTarget) -> [String] {
        let declared = target.settings.flatMap { setting -> [String] in
            guard setting.name == "define" else { return [] }
            guard setting.tool == "c" || setting.tool == "cxx" else { return [] }
            return setting.values
        }

        return (["SWIFT_PACKAGE"] + declared).map { "-D\($0)" }
    }
}
