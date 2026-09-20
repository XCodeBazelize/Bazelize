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
        generated: PluginGenerated,
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        guard let directory = sourceDirectory(of: target, in: package) else { return }

        let module = Self.moduleName(target.name)
        let extensions = extensions(of: target, in: package)
        let headers = publicHeaders(of: target, in: directory)
        let compiled = Self.compileExtensions.filter { extensions.contains($0) }
        /// Headers are matched against everything on disk: `exclude` can drop a
        /// directory that a header search path still points into.
        let files = relativeFiles(of: target, in: package, prefix: prefix, excluding: false)

        /// The module map is what names the module: without one the name comes
        /// from the label, and neither a Swift `import` nor a C-family `@import` of
        /// the target's own name resolves. A map the package wrote itself is kept,
        /// because it is the interface the package intends.
        let name = ruleName(of: target.name, in: package)
        let hint = "\(name)_interop"
        let headerPrefix = headers.map { Self.path(prefix, $0) }
        let interface = try? mirror(
            headersOf: target,
            at: headers.map { directory + $0 },
            module: module,
            root: root)

        builder.load(loadableRule: Rules.Swift.swift_interop_hint)
        builder.call(
            Rules.Swift.Call.swift_interop_hint(
                name: hint,
                module_map: interface.map { .named("\($0)/module.modulemap") },
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
                        /// A plugin's output compiles like a source of the target,
                        /// and the header beside it is an input the same way a
                        /// private header is: the generated source includes it by
                        /// name, which is all SwiftPM offers either.
                        + generated.sources
                        + generated.headers
                        + (resources?.accessors ?? []),
                    exclude: excludedClang(target, prefix: prefix)
                        + (headerPrefix.map { $0 == prefix ? [] : ["\($0)/**"] } ?? []),
                    allowEmpty: true),
                hdrs: interface
                    .map { path in
                        matching(
                            Self.headerExtensions.map { "\(path)/**/*.\($0)" },
                            Self.relativeFiles(under: path, in: root))
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
                includes: includes(
                    of: target,
                    prefix: prefix,
                    interface: interface).nonEmpty,
                linkopts: linkopts(of: target).nonEmpty,
                /// The module a dependent's `@import` names: the package target's
                /// own name, not the one Bazel derives from the label.
                module_name: module,
                tags: Self.manual,
                /// The map travels with the headers: it is on the include path of
                /// everything that depends on the target, and clang has to find the
                /// file there.
                textual_hdrs: interface.map { path in
                    .build { [Starlark.Label.named("\(path)/module.modulemap")] }
                },
                visibility: .public))
    }

    /// The files of a generated directory, named the way a glob pattern is.
    private static func relativeFiles(under directory: String, in root: Path) -> [String] {
        let base = root.normalize().string

        return SwiftPM.Generator.walk(root + directory).compactMap { file in
            let path = file.normalize().string
            guard path.hasPrefix(base) else { return nil }
            return String(path.dropFirst(base.count)).trimmingCharacters(in: ["/"])
        }
    }

    /// The target's public interface: its headers and the module map, in one
    /// directory of our own.
    ///
    /// clang looks for `module.modulemap` in the directory a header was found in,
    /// so the map has to sit next to the headers — and the checkout is not ours to
    /// write into. The headers are therefore linked into a generated directory
    /// beside the map, the way an Xcode target's flattened header tree works. Every
    /// consumer then resolves the module through a header search path alone: a
    /// Swift `import`, a C-family `@import`, from this package or any other.
    private func mirror(
        headersOf target: SwiftPM.PackageTarget,
        at headers: Path?,
        module: String,
        root: Path) throws -> String?
    {
        guard let headers, headers.isDirectory else { return nil }

        let relative = "Generated/\(target.name)Interface"
        let interface = root + relative
        if interface.exists || interface.isSymlink {
            try? interface.delete()
        }
        try interface.mkpath()

        let files = SwiftPM.Generator.walk(headers)
        let base = headers.normalize().string
        var shipped: Path?

        for file in files {
            let path = file.normalize().string
            guard path.hasPrefix(base) else { continue }

            let name = String(path.dropFirst(base.count)).trimmingCharacters(in: ["/"])
            if name == "module.modulemap" {
                shipped = file
                continue
            }

            let link = interface + name
            try link.parent().mkpath()
            try link.symlink(file)
        }

        /// A map the package ships is its intended interface; without one the
        /// module is every header in the directory, which is what SwiftPM
        /// generates for a clang target too.
        let map = interface + "module.modulemap"
        if let shipped {
            try map.symlink(shipped)
        } else {
            try map.write("""
            module \(module) {
                umbrella "."
                export *
            }

            """)
        }

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

    /// What a header lookup can reach: the target's interface directory and
    /// whatever `headerSearchPath` adds, which is the shape SwiftPM passes.
    ///
    /// Not the target directory itself: a module map sitting there would be found
    /// by clang on its own, and a package that ships one outside its public
    /// headers would end up with two maps for the same module.
    private func includes(
        of target: SwiftPM.PackageTarget,
        prefix: String,
        interface: String?) -> [String]
    {
        var paths: [String] = []
        if let interface {
            paths.append(interface)
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
