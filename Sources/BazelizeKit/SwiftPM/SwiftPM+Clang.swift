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
        let extensions = extensions(of: target, in: package)
        let headers = publicHeaders(of: target, in: directory)
        let compiled = Self.compileExtensions.filter { extensions.contains($0) }
        let present = Set(allFiles(of: target, in: package).compactMap(\.extension))
        let headerExtensions = Self.headerExtensions.filter { present.contains($0) }

        /// The hint is what names the module: without it the module is named after
        /// the label, and a Swift `import` of the target's own name fails. A module
        /// map the package wrote itself replaces the generated one, because it is
        /// the interface the package intends.
        let hint = "\(target.name)_interop"
        let headerPrefix = headers.map { Self.path(prefix, $0) }
        let moduleMap = headerPrefix
            .map { "\($0)/module.modulemap" }
            .flatMap { path -> String? in
                (root + path).exists ? path : nil
            }

        builder.load(loadableRule: Rules.Swift.swift_interop_hint)
        builder.call(
            Rules.Swift.Call.swift_interop_hint(
                name: hint,
                module_map: moduleMap.map { .named($0) },
                module_name: module))

        builder.load(loadableRule: Rules.Objc.objc_library)
        builder.call(
            Rules.Objc.Call.objc_library(
                name: target.name,
                aspect_hints: .build { [Starlark.Label.named(":\(hint)")] },
                srcs: Starlark.glob(
                    sources(of: target, prefix: prefix, extensions: compiled)
                        /// Private headers are compilation inputs wherever they
                        /// sit, so they are collected from the whole directory even
                        /// when the sources are listed one by one.
                        + (headerPrefix == prefix
                            ? []
                            : headerExtensions.map { "\(prefix)/**/*.\($0)" })
                        + (resources?.accessors ?? []),
                    exclude: excluded(target, prefix: prefix)
                        + (headerPrefix.map { $0 == prefix ? [] : ["\($0)/**"] } ?? [])),
                hdrs: headerExtensions.isEmpty ? nil : headerPrefix.map { path in
                    Starlark.glob(headerExtensions.map { "\(path)/**/*.\($0)" })
                },
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
                tags: ["manual"],
                visibility: .public))
    }

    /// `publicHeadersPath`, defaulting to the `include` directory SwiftPM looks
    /// for. It can also be `.`, meaning the target's own directory.
    private func publicHeaders(of target: SwiftPM.PackageTarget, in directory: Path) -> String? {
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
