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
import Xcode

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
        let compiled = Self.compileExtensions.filter { extensions.contains($0.rawValue) }
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
                module_map: interface.map { .named("\($0.root)/module.modulemap") },
                module_name: module))

        builder.load(loadableRule: Rules.Objc.objc_library)
        builder.call(
            Rules.Objc.Call.objc_library(
                name: name,
                aspect_hints: .build { [Starlark.Label.named(":\(hint)")] },
                srcs: sources(
                    naming: resources?.accessors ?? [],
                    globbing: matching(
                        sources(of: target, prefix: prefix, extensions: compiled)
                            /// Private headers are compilation inputs wherever they
                            /// sit, so they are collected from the whole directory
                            /// even when the sources are listed one by one. A target
                            /// whose public headers are its own directory needs them
                            /// too: a `#include "sibling.hpp"` is resolved beside the
                            /// source, not through the mirrored interface.
                            + Self.headerExtensions.map { "\(prefix)/**/*.\($0.rawValue)" },
                        files)
                        /// A plugin's output compiles like a source of the target,
                        /// and the header beside it is an input the same way a
                        /// private header is: the generated source includes it by
                        /// name, which is all SwiftPM offers either.
                        + generated.sources
                        + generated.headers,
                    excluding: excludedClang(target, prefix: prefix)
                        + (headerPrefix.map { $0 == prefix ? [] : ["\($0)/**"] } ?? [])),
                hdrs: interface
                    .map { matching(Self.headerExtensions.map(\.rawValue), under: $0.roots, in: root) }?
                    .nonEmpty
                    .map { Starlark.glob($0) },
                deps: deps(of: target, in: package),
                data: resources?.labels.nonEmpty.map { labels in
                    .build { labels.map { Starlark.Label.named($0) } }
                },
                alwayslink: true,
                copts: clangCopts(
                    of: target,
                    in: package,
                    module: module,
                    compiled: compiled,
                    resources: resources),
                enable_modules: true,
                includes: includes(
                    of: target,
                    prefix: prefix,
                    interface: interface).nonEmpty,
                linkopts: linkopts(of: target, in: package),
                /// The module a dependent's `@import` names: the package target's
                /// own name, not the one Bazel derives from the label.
                module_name: module,
                tags: Self.manual,
                /// The maps travel with the headers: they are on the include path
                /// of everything that depends on the target, and clang has to find
                /// the files there. Not only the target's own: a map in a
                /// subdirectory of the public headers declares a module of its own,
                /// which clang finds as `<search path>/<module>/module.modulemap`
                /// — the target is then two modules, and either can be imported.
                textual_hdrs: interface
                    .map { matching(["modulemap"], under: $0.roots, in: root) }?
                    .nonEmpty
                    .map { Starlark.glob($0) },
                visibility: .public))
    }

    /// The library a C-family test target compiles into.
    ///
    /// A test module is linked into a bundle and imported by nothing, so it
    /// needs neither a module map nor an interface directory: what it has is
    /// its sources, the headers beside them, and whatever it was told to
    /// compile with. SwiftPM compiles such a target like any other C-family
    /// one, and a `swift_library` over no Swift sources is a rule Bazel
    /// rejects — taking the whole package with it.
    func buildClangTest(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        name: String,
        generated: [String],
        resources: ResourceBundle?,
        builder: CodeBuilder)
    {
        let extensions = extensions(of: target, in: package)
        let compiled = Self.compileExtensions.filter { extensions.contains($0.rawValue) }
        /// Headers are matched against everything on disk, the way a regular
        /// C-family target matches them: a header beside a test source is an
        /// input of its compile.
        let files = relativeFiles(of: target, in: package, prefix: prefix, excluding: false)

        builder.load(loadableRule: Rules.Objc.objc_library)
        builder.call(
            Rules.Objc.Call.objc_library(
                name: name,
                srcs: sources(
                    naming: resources?.accessors ?? [],
                    globbing: matching(
                        sources(of: target, prefix: prefix, extensions: compiled)
                            + Self.headerExtensions.map { "\(prefix)/**/*.\($0.rawValue)" },
                        files)
                        + generated,
                    excluding: excludedClang(target, prefix: prefix)),
                deps: deps(of: target, in: package),
                data: resources?.labels.nonEmpty.map { labels in
                    .build { labels.map { Starlark.Label.named($0) } }
                },
                /// A test case is discovered by the runtime rather than called,
                /// so the linker must not drop it for having no references.
                alwayslink: true,
                copts: clangCopts(
                    of: target,
                    in: package,
                    module: Self.moduleName(target.name),
                    compiled: compiled,
                    resources: resources),
                enable_modules: true,
                linkopts: linkopts(of: target, in: package),
                module_name: Self.moduleName(target.name),
                tags: Self.manual,
                testonly: true,
                visibility: .private))
    }

    /// The patterns for files of these extensions anywhere below the generated
    /// directories, keeping only those that match something.
    private func matching(_ extensions: [String], under directories: [String], in root: Path) -> [String] {
        directories.flatMap { directory in
            matching(
                extensions.map { "\(directory)/**/*.\($0)" },
                Self.relativeFiles(under: directory, in: root))
        }
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

    /// Where a target's public headers are reached from.
    private struct Interface {
        /// The directory holding the target's module map.
        let root: String
        /// Every directory a header lookup goes through, the root first.
        let roots: [String]
    }

    /// The target's public interface: its headers and the module map, in a
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
        root: Path) throws
        -> Interface?
    {
        guard let headers, headers.isDirectory else { return nil }

        let relative = "Generated/\(target.name)Interface"
        let linkedRelative = "Generated/\(target.name)LinkedInterface"
        for directory in [relative, linkedRelative] {
            let path = root + directory
            if path.exists || path.isSymlink {
                try? path.delete()
            }
        }
        let interface = root + relative
        try interface.mkpath()

        let shippedMap = headers + "module.modulemap"
        let shipped = shippedMap.isFile ? shippedMap : nil

        let files = SwiftPM.Generator.walk(headers)
        let base = headers.normalize().string
        var linked = false

        for file in files {
            let path = file.normalize().string
            guard path.hasPrefix(base) else { continue }

            let name = String(path.dropFirst(base.count)).trimmingCharacters(in: ["/"])
            if name == "module.modulemap" { continue }

            /// Without a map of the package's own, the module is an umbrella over
            /// the directory, and clang's walk of an umbrella does not enter a
            /// directory that is a symlink: what sits behind one is in no module
            /// of the target's, unless a map beside it declares one. The mirror
            /// is real directories all the way down, so those files go to a
            /// second directory on the include path instead, at the same path
            /// below it. A lookup finds them as it did, and the umbrella does
            /// not: left under it, a header a nested map owns would be in both
            /// modules, and the two would include each other. An `exclude
            /// header` cannot say the same — it takes a header away from the
            /// nested map's umbrella directory too.
            ///
            /// A shipped map names its headers relative to itself, so with one
            /// the tree stays whole.
            let behindLink = shipped == nil && Self.isBehindDirectoryLink(name, in: headers)
            linked = linked || behindLink

            let link = root + (behindLink ? linkedRelative : relative) + name
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

        return Interface(root: relative, roots: linked ? [relative, linkedRelative] : [relative])
    }

    /// Whether a path under `directory` passes through a directory symlink.
    private static func isBehindDirectoryLink(_ name: String, in directory: Path) -> Bool {
        let components = name.split(separator: "/").dropLast()
        var current = directory
        for component in components {
            current = current + String(component)
            if current.isSymlink { return true }
        }
        return false
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
            let `extension` = Path(excluded).extension

            if searched.contains(path) {
                return Self.compileExtensions.map { "\(prefix)/\(path)/**/*.\($0.rawValue)" }
            }

            /// A header a manifest excludes is excluded from being compiled, which
            /// it never was: it is included by a source beside it, and dropping it
            /// leaves the compiler looking for a file the sandbox does not have.
            if
                let `extension`, let header = FileExtension(rawValue: `extension`),
                Self.headerExtensions.contains(header)
            {
                return []
            }

            return `extension` == nil
                ? ["\(prefix)/\(path)/**"]
                : ["\(prefix)/\(path)"]
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

    /// What a header lookup can reach: the target's interface directories and
    /// whatever `headerSearchPath` adds, which is the shape SwiftPM passes.
    ///
    /// Not the target directory itself: a module map sitting there would be found
    /// by clang on its own, and a package that ships one outside its public
    /// headers would end up with two maps for the same module.
    private func includes(
        of target: SwiftPM.PackageTarget,
        prefix: String,
        interface: Interface?)
        -> [String]
    {
        var paths: [String] = interface?.roots ?? []

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
        compiled: [FileExtension],
        resources: ResourceBundle?)
        -> Starlark.Value?
    {
        var always = ["-fmodule-name=\(module)", "-DSWIFT_PACKAGE"]

        /// SwiftPM force-includes the accessor, so a source reaches its bundle
        /// without importing anything.
        if let header = resources?.header {
            always.append("-include$(execpath \(header))")
        }

        always += standards(of: target, in: package, compiled: compiled)

        return grouped(target.settings, in: package, always: always, flags: Self.clangFlags)
    }

    /// The flags of one C-family setting.
    ///
    /// Flags, not the `defines` attribute, for the same reason as a Swift
    /// target: the attribute would propagate into everything downstream.
    private static func clangFlags(_ setting: SwiftPM.Setting) -> [String] {
        guard setting.tool == "c" || setting.tool == "cxx" else { return [] }

        switch setting.name {
        case "define":
            /// `.define("A", to: "1")` is dumped as two values, and is one
            /// flag: `-DA=1`.
            return setting.values.nonEmpty.map { ["-D\($0.joined(separator: "="))"] } ?? []
        case "unsafeFlags":
            return setting.values
        /// `treatAllWarnings(as:)` and `treatWarning(_:as:)`, which clang spells
        /// as `-Werror` over everything and `-W{error,no-error}=<name>` over one
        /// warning.
        case "treatAllWarnings":
            guard let level = setting.values.first else { return [] }
            return level == "error" ? ["-Werror"] : ["-Wno-error"]
        case "treatWarning":
            guard setting.values.count == 2 else { return [] }
            let group = setting.values[0]
            return setting.values[1] == "error" ? ["-Werror=\(group)"] : ["-Wno-error=\(group)"]
        default:
            return []
        }
    }

    /// `-std=`, for the language the target is actually written in.
    ///
    /// SwiftPM compiles each file with the standard of its own language; one
    /// rule has one `copts`, and clang rejects a C standard for a C++ file as
    /// firmly as the other way round. So the standard is the one that fits what
    /// the target compiles, and a target that compiles both is named instead of
    /// being given a flag that breaks half of it.
    private func standards(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        compiled: [FileExtension])
        -> [String]
    {
        let extensions = Set(compiled)
        let cxx = !extensions.isDisjoint(with: Self.cxxExtensions)
        let c = !extensions.isDisjoint(with: Self.cExtensions)

        switch (c, cxx) {
        case (true, false):
            return package.manifest.cLanguageStandard.map { ["-std=\($0)"] } ?? []
        case (false, true):
            return package.manifest.cxxLanguageStandard.map { ["-std=\($0)"] } ?? []
        case (true, true):
            guard package.manifest.cLanguageStandard != nil || package.manifest.cxxLanguageStandard != nil else {
                return []
            }

            let message = """
            \(package.directory)'s \(target.name) compiles C and C++ in one target, \
            and one rule takes one `-std`: the language standards the package \
            declares are left off.
            """
            note(message)
            return []
        case (false, false):
            return []
        }
    }

    private static let cExtensions: Set<FileExtension> = [.c, .m]
    private static let cxxExtensions: Set<FileExtension> = [.cc, .cpp, .cxx, .cPlusPlus, .mm]
}
