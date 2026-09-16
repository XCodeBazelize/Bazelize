//
//  SwiftPM+Generator.swift
//
//
//  Bazel rules for the Swift packages a project depends on.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM {
    /// Writes one `BUILD` per package under `Packages/`, plus the source tree it
    /// points at.
    ///
    /// The layout matches what `Targets/` already does: a symlink tree of the
    /// sources and a generated `BUILD` beside it. Nothing outside `Packages/`
    /// changes — a target reaches a product through the facade either way.
    struct Generator {
        let output: Path
        let workspace: Workspace

        func generate() throws {
            for package in workspace.packages {
                try generate(package)
            }
        }

        // MARK: Private

        private var packagesRoot: Path {
            output + PluginSwiftPM.packagesDirectory
        }

        private func generate(_ package: Package) throws {
            let root = packagesRoot + package.directory
            try root.mkpath()
            try materializeSources(package, at: root)

            let builder = CodeBuilder()
            var emitted = try supportedTargets(of: package)

            for target in package.manifest.targets {
                guard let kind = emitted[target.name] else { continue }

                if case .binary = kind {
                    if try !buildBinary(target, in: package, root: root, builder: builder) {
                        emitted[target.name] = nil
                    }
                    continue
                }

                guard let prefix = sourcePrefix(of: target, in: package) else { continue }

                let resources = try buildResources(
                    target,
                    in: package,
                    prefix: prefix,
                    root: root,
                    kind: kind,
                    builder: builder)

                switch kind {
                case .swift:
                    build(
                        target,
                        in: package,
                        prefix: prefix,
                        resources: resources,
                        builder: builder)
                case .clang:
                    buildClang(
                        target,
                        in: package,
                        prefix: prefix,
                        root: root,
                        resources: resources,
                        builder: builder)
                case .binary, .unsupported:
                    continue
                }
            }

            for product in package.manifest.products {
                build(product, emitted: Set(emitted.keys), package: package, builder: builder)
            }

            try (root + "BUILD").write(builder.build())
        }

        /// The targets that can be generated, after dropping everything that depends
        /// on one that cannot: a library missing a target it links is worse than a
        /// library that is not there at all.
        private func supportedTargets(of package: Package) throws -> [String: TargetKind] {
            let targets = package.manifest.targets.filter { $0.type != "test" }
            var supported: [String: TargetKind] = [:]

            for target in targets {
                guard let kind = try kind(of: target, in: package) else { continue }
                switch kind {
                case .swift, .clang, .binary:
                    supported[target.name] = kind
                case .unsupported(let reason):
                    Log.codeGenerate.warning("""
                    Skip \(package.directory, privacy: .public)/\(target.name, privacy: .public): \
                    \(reason, privacy: .public)
                    """)
                }
            }

            let names = Set(targets.map(\.name))
            var changed = true
            while changed {
                changed = false
                for target in targets where supported[target.name] != nil {
                    let missing = target.dependencies.compactMap { dependency -> String? in
                        switch dependency.kind {
                        case .target(let name), .byName(let name):
                            guard names.contains(name), supported[name] == nil else { return nil }
                            return name
                        case .product:
                            return nil
                        }
                    }
                    guard let first = missing.first else { continue }

                    supported[target.name] = nil
                    changed = true
                    Log.codeGenerate.warning("""
                    Skip \(package.directory, privacy: .public)/\(target.name, privacy: .public): \
                    depends on \(first, privacy: .public), which is not generated
                    """)
                }
            }

            return supported
        }

        /// The sources stay where SwiftPM put them; the package directory only
        /// carries a link to them, the way a target's `Sources/` does.
        private func materializeSources(_ package: Package, at root: Path) throws {
            let destination = root + Self.sourcesRoot
            if destination.isSymlink || destination.exists {
                try? destination.delete()
            }
            try destination.symlink(package.root)
        }

        static let sourcesRoot = "Package"

        enum TargetKind {
            case swift
            case clang
            case binary
            case unsupported(String)
        }

        /// What the target is made of, decided by the files on disk: the manifest
        /// only says `regular`.
        private func kind(of target: PackageTarget, in package: Package) throws -> TargetKind? {
            switch target.type {
            case "test":
                return nil
            case "plugin":
                /// Every plugin in the wild so far is a linter: it produces no
                /// source, so a build without it is the same build.
                return .unsupported("plugin targets are not generated")
            case "binary":
                return .binary
            case "system":
                return .unsupported("system library targets are not generated yet")
            case "macro":
                return .unsupported("macro targets are not generated yet")
            default:
                break
            }

            guard let directory = sourceDirectory(of: target, in: package) else {
                return .unsupported("no source directory")
            }

            let extensions = extensions(of: target, in: package)
            guard !extensions.isEmpty else {
                return .unsupported("no sources")
            }

            /// A target with any Swift in it is a Swift target: SwiftPM does not
            /// allow one target to mix languages, so the C-family files that are
            /// still on disk belong to another target or are excluded.
            return extensions.contains("swift") ? .swift : .clang
        }

        /// The extensions of the files that actually belong to the target, which is
        /// what decides whether a `regular` target is Swift or C-family.
        func extensions(of target: PackageTarget, in package: Package) -> Set<String> {
            Set(sourceFiles(of: target, in: package).compactMap(\.extension))
        }

        /// The files SwiftPM compiles for the target: what an explicit `sources`
        /// list names, or the whole target directory, minus `exclude`.
        func sourceFiles(of target: PackageTarget, in package: Package) -> [Path] {
            guard let directory = sourceDirectory(of: target, in: package) else { return [] }
            let roots = (target.sources?.nonEmpty?.map { directory + $0 }) ?? [directory]
            return files(under: roots, excluding: target.exclude, in: directory)
        }

        /// Everything in the target directory, `exclude` aside.
        ///
        /// An explicit `sources` list only stops SwiftPM from compiling the rest;
        /// a header next to those sources is still the target's header, which is
        /// why it is collected from the whole directory.
        func allFiles(of target: PackageTarget, in package: Package) -> [Path] {
            guard let directory = sourceDirectory(of: target, in: package) else { return [] }
            return files(under: [directory], excluding: target.exclude, in: directory)
        }

        private func files(under roots: [Path], excluding exclude: [String], in directory: Path) -> [Path] {
            let excluded = exclude.map { (directory + $0).normalize().string }

            var files: [Path] = []
            for root in roots {
                if root.isDirectory {
                    files.append(contentsOf: ((try? root.recursiveChildren()) ?? []))
                } else if root.exists {
                    files.append(root)
                }
            }

            return files.filter { file in
                let path = file.normalize().string
                return !excluded.contains { path == $0 || path.hasPrefix("\($0)/") }
            }
        }

        /// Extensions a C-family compiler is handed.
        static let compileExtensions = ["c", "cc", "cpp", "cxx", "m", "mm", "S", "s"]
        /// Extensions that are only ever included by another file.
        static let headerExtensions = ["h", "hh", "hpp", "hxx", "inc"]

        /// SwiftPM's own layout rules: an explicit `path`, else one of the
        /// conventional directories, else the package root for a single target.
        func sourceDirectory(of target: PackageTarget, in package: Package) -> Path? {
            if let path = target.path {
                let directory = (package.root + path).normalize()
                return directory.exists ? directory : nil
            }

            for candidate in ["Sources", "Source", "src", "srcs"] {
                let directory = package.root + candidate + target.name
                if directory.exists { return directory }
            }

            let flat = package.root + target.name
            return flat.exists ? flat : nil
        }

        /// The target's directory, relative to the package's source link.
        func sourcePrefix(of target: PackageTarget, in package: Package) -> String? {
            guard let directory = sourceDirectory(of: target, in: package) else { return nil }

            let root = package.root.normalize().string
            let path = directory.normalize().string
            guard path.hasPrefix(root) else { return nil }

            let relative = String(path.dropFirst(root.count)).trimmingCharacters(in: ["/"])
            return relative.isEmpty ? Self.sourcesRoot : "\(Self.sourcesRoot)/\(relative)"
        }

        private func build(
            _ target: PackageTarget,
            in package: Package,
            prefix: String,
            resources: ResourceBundle?,
            builder: CodeBuilder)
        {
            builder.load(loadableRule: Rules.Swift.swift_library)
            builder.call(
                Rules.Swift.Call.swift_library(
                    name: target.name,
                    /// SwiftPM compiles every package target with the developer
                    /// search paths, which is how a test-support library finds
                    /// XCTest.
                    always_include_developer_search_paths: true,
                    copts: copts(of: target).nonEmpty,
                    module_name: Self.moduleName(target.name),
                    /// Which targets `package` visibility reaches: every target of
                    /// the same package, which is what the name identifies.
                    package_name: package.manifest.name,
                    srcs: Starlark.glob(
                        sources(of: target, prefix: prefix, extensions: ["swift"])
                            + (resources?.accessors ?? []),
                        exclude: excluded(target, prefix: prefix)),
                    deps: deps(of: target, in: package).nonEmpty.map { labels in
                        .build { labels }
                    },
                    data: resources.map { bundle in
                        .build { [Starlark.Label.named(bundle.label)] }
                    },
                    linkopts: linkopts(of: target).nonEmpty,
                    /// A package target is built through the bundle rule that
                    /// transitions it to a platform; building it on its own would
                    /// compile an iOS-only package for the host.
                    tags: ["manual"],
                    visibility: .public))
        }

        /// An explicit `sources` list names files or directories; without one the
        /// whole target directory is the target.
        func sources(of target: PackageTarget, prefix: String, extensions: [String]) -> [String] {
            guard let sources = target.sources, !sources.isEmpty else {
                return extensions.map { "\(prefix)/**/*.\($0)" }
            }

            return sources.flatMap { source -> [String] in
                guard let fileExtension = Path(source).extension else {
                    return extensions.map { "\(prefix)/\(source)/**/*.\($0)" }
                }
                return extensions.contains(fileExtension) ? ["\(prefix)/\(source)"] : []
            }
        }

        /// `exclude` names a file or a directory; a directory excludes everything
        /// under it.
        func excluded(_ target: PackageTarget, prefix: String) -> [String] {
            target.exclude.flatMap { excluded -> [String] in
                Path(excluded).extension == nil
                    ? ["\(prefix)/\(excluded)/**"]
                    : ["\(prefix)/\(excluded)"]
            }
        }

        func deps(of target: PackageTarget, in package: Package) -> [Starlark.Label] {
            let localTargets = Set(package.manifest.targets.map(\.name))
            let localProducts = Dictionary(
                package.manifest.products.map { ($0.name, $0) },
                uniquingKeysWith: { first, _ in first })

            let labels: [String] = target.dependencies.compactMap { dependency in
                switch dependency.kind {
                case .target(let name):
                    return localTargets.contains(name) ? ":\(name)" : nil
                case .byName(let name):
                    if localTargets.contains(name) { return ":\(name)" }
                    if localProducts[name] != nil { return ":\(name)" }
                    return label(product: name, package: nil, from: package)
                case .product(let name, let packageName):
                    return label(product: name, package: packageName, from: package)
                }
            }

            return Array(Set(labels)).sorted().map(Starlark.Label.named)
        }

        /// A product of another package is reached through the facade, so the label
        /// does not depend on how that package's rules are generated.
        private func label(product: String, package name: String?, from package: Package) -> String? {
            let identities = [name, product].compactMap { $0 }
                + package.manifest.dependencies.map(\.identity)

            for identity in identities {
                guard let directory = workspace.directoryByIdentity[identity.lowercased()] else { continue }
                return "//\(PluginSwiftPM.packagesDirectory)/\(directory):\(product)"
            }

            Log.codeGenerate.warning("""
            No package for product \(product, privacy: .public) \
            required by \(package.directory, privacy: .public)
            """)
            return nil
        }

        private func build(
            _ product: PackageProduct,
            emitted: Set<String>,
            package: Package,
            builder: CodeBuilder)
        {
            guard product.kind == .library else { return }

            let targets = product.targets.filter { emitted.contains($0) }
            guard !targets.isEmpty else { return }

            /// A product of one target is that target under another name; several
            /// targets are a group that exports all of them.
            if targets.count == 1, let target = targets.first {
                guard target != product.name else { return }

                builder.call(
                    Rules.Builtin.Call.alias(
                        name: product.name,
                        actual: .named(":\(target)"),
                        visibility: .public))
                return
            }

            builder.load(loadableRule: Rules.Swift.swift_library_group)
            builder.call(
                Rules.Swift.Call.swift_library_group(
                    name: product.name,
                    deps: .build {
                        targets.sorted().map { target in
                            Starlark.Label.named(":\(target)")
                        }
                    },
                    visibility: .public))
        }

        /// Swift module names are identifiers; a package name is not.
        static func moduleName(_ name: String) -> String {
            String(name.map { character in
                character.isLetter || character.isNumber || character == "_" ? character : "_"
            })
        }
    }
}
