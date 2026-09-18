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
    final class Generator {
        let output: Path
        let workspace: Workspace

        let deployment: Deployment

        private var kinds: [String: [String: TargetKind]] = [:]

        /// What a caller tells the user about: where the build differs from what
        /// the package asked for, and why.
        private(set) var notes: [String] = []

        init(output: Path, workspace: Workspace, deployment: Deployment) {
            self.output = output
            self.workspace = workspace
            self.deployment = deployment
        }

        func generate() throws {
            notes.append(contentsOf: workspace.pluginOutputs.notes)

            for package in workspace.packages {
                kinds[package.directory] = try supportedTargets(of: package)
                report(deploymentOf: package)
                report(pluginsOf: package)
            }

            for package in workspace.packages {
                try generate(package)
            }
        }

        /// A package that declares a platform version the project does not reach is
        /// compiled at the project's version anyway, and fails in whichever newer
        /// API it uses. The reason is in the manifest, not in that error, so it is
        /// said out loud.
        private func report(deploymentOf package: Package) {
            for unmet in deployment.unmet(package) {
                let message = """
                \(package.directory) declares \(unmet.platform) \(unmet.required), \
                and the project builds \(unmet.platform) \(unmet.project): \
                the package is compiled at \(unmet.project) and may not support it.
                """

                Log.codeGenerate.warning("\(message, privacy: .public)")
                notes.append(message)
            }
        }

        /// A dependency's build tool plugin is not run.
        ///
        /// The plugins of a package in the project's own repository are run while
        /// the workspace is generated; a dependency's are not, because running one
        /// costs a SwiftPM build of its package. Every plugin in the corpus is a
        /// linter, which produces no source: a build without it is the same build.
        /// One that generates source would leave a target missing the files it
        /// expects, and that compile error says nothing about a plugin, so the
        /// plugin is named here instead.
        private func report(pluginsOf package: Package) {
            guard !package.isRoot, !package.isLocal else { return }

            let used = package.manifest.targets
                .filter { $0.type != "test" }
                .flatMap(\.pluginUsages)
                .map(\.name)

            for plugin in Set(used).sorted() {
                let message = """
                \(package.directory) asks for the \(plugin) plugin, which is not run: \
                a linter changes nothing, a plugin that generates source does.
                """

                Log.codeGenerate.warning("\(message, privacy: .public)")
                notes.append(message)
            }
        }

        // MARK: Private

        private var packagesRoot: Path {
            output + PluginSwiftPM.packagesDirectory
        }

        private func generate(_ package: Package) throws {
            let root = packagesRoot + package.directory
            try root.mkpath()

            let builder = CodeBuilder()
            var emitted = kinds[package.directory] ?? [:]

            for target in package.manifest.targets {
                guard let kind = emitted[target.name] else { continue }

                if case .binary = kind {
                    if try !buildBinary(target, in: package, root: root, builder: builder) {
                        emitted[target.name] = nil
                    }
                    continue
                }

                guard let prefix = try materialize(target, in: package, at: root) else { continue }

                if case .system = kind {
                    if !buildSystemLibrary(
                        target,
                        in: package,
                        prefix: prefix,
                        root: root,
                        builder: builder)
                    {
                        emitted[target.name] = nil
                    }
                    continue
                }

                let generated = try materialize(
                    pluginOutputsOf: target,
                    in: package,
                    at: root,
                    kind: kind)

                let resources = try buildResources(
                    target,
                    in: package,
                    prefix: prefix,
                    root: root,
                    kind: kind,
                    generated: generated.resources,
                    builder: builder)

                switch kind {
                case .macro:
                    buildMacro(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        builder: builder)
                case .executable:
                    buildExecutable(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        resources: resources,
                        builder: builder)
                case .test:
                    buildTest(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        resources: resources,
                        builder: builder)
                case .swift:
                    build(
                        target,
                        in: package,
                        prefix: prefix,
                        generated: generated.sources,
                        resources: resources,
                        builder: builder)
                case .clang:
                    buildClang(
                        target,
                        in: package,
                        prefix: prefix,
                        root: root,
                        generated: generated,
                        resources: resources,
                        builder: builder)
                case .binary, .system, .unsupported:
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
            /// Which targets are generated is `kind(of:)`'s answer, tests included:
            /// the package under the tool gets its tests, one a project depends on
            /// does not.
            let targets = package.manifest.targets
            var supported: [String: TargetKind] = [:]

            for target in targets {
                guard let kind = try kind(of: target, in: package) else { continue }
                switch kind {
                case .swift, .clang, .binary, .system, .macro, .executable, .test:
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

        /// What a plugin generated, linked next to the package's rules.
        ///
        /// Split the way SwiftPM splits it: a file whose extension the target
        /// compiles is a source of that target, anything else is one of its
        /// resources. A header is neither compiled nor bundled — it is an input of
        /// the generated source that includes it, which is the only thing SwiftPM
        /// lets reach it too.
        struct PluginGenerated {
            let sources: [String]
            let headers: [String]
            let resources: [String]

            static let none = PluginGenerated(sources: [], headers: [], resources: [])
        }

        func materialize(
            pluginOutputsOf target: PackageTarget,
            in package: Package,
            at root: Path,
            kind: TargetKind) throws -> PluginGenerated
        {
            let files = workspace.pluginOutputs.files(of: target.name, in: package)
            guard !files.isEmpty else { return .none }

            let directory = "Generated/\(target.name)Plugin"
            let generated = root + directory
            if generated.exists || generated.isSymlink {
                try? generated.delete()
            }
            try generated.mkpath()

            /// What the target's own rule compiles; a Swift target compiles Swift,
            /// and a C-family one whatever clang takes.
            let compiled: Set<String> = {
                if case .clang = kind { return Set(Self.compileExtensions) }
                return ["swift"]
            }()

            var sources: [String] = []
            var headers: [String] = []
            var resources: [String] = []

            for file in files {
                let link = generated + file.lastComponent
                try link.symlink(file)

                let path = "\(directory)/\(file.lastComponent)"
                let `extension` = file.extension ?? ""
                if compiled.contains(`extension`) {
                    sources.append(path)
                } else if Self.headerExtensions.contains(`extension`) {
                    headers.append(path)
                } else {
                    resources.append(path)
                }
            }

            return .init(sources: sources, headers: headers, resources: resources)
        }

        /// The sources stay where SwiftPM put them; the package directory carries
        /// one link per target, the way a target's `Sources/` does.
        ///
        /// A link per target rather than one for the whole checkout is what keeps
        /// the rest of the checkout out of the build: a package can ship `BUILD`
        /// files of its own — swift-syntax and Yams both do — and Bazel would load
        /// them as packages of this workspace.
        private func materialize(_ target: PackageTarget, in package: Package, at root: Path) throws -> String? {
            guard let directory = sourceDirectory(of: target, in: package) else { return nil }

            let prefix = "\(Self.sourcesRoot)/\(target.name)"
            let link = root + prefix
            try link.parent().mkpath()
            if link.isSymlink || link.exists {
                try? link.delete()
            }

            /// One link for the whole directory is what a target's sources are, but
            /// a package can keep a symlink pointing back into that directory —
            /// GRDB's test fixtures do — and Bazel cannot glob through the cycle.
            /// Such a tree is mirrored instead, entry by entry, without the link
            /// that closes the loop.
            if Self.hasCycle(directory) {
                try Self.mirror(directory, at: link)
            } else {
                try link.symlink(directory)
            }

            return prefix
        }

        /// Whether anything under the directory links back into it.
        private static func hasCycle(_ directory: Path) -> Bool {
            let root = directory.url.resolvingSymlinksInPath().path

            for entry in entries(of: directory) where entry.isSymlink {
                let resolved = entry.url.resolvingSymlinksInPath().path
                if root == resolved || root.hasPrefix("\(resolved)/") { return true }
            }

            return false
        }

        /// A copy of the directory's shape, with one link per file.
        private static func mirror(_ directory: Path, at destination: Path) throws {
            try destination.mkpath()

            let root = directory.url.resolvingSymlinksInPath().path
            for child in (try? directory.children()) ?? [] {
                let target = destination + child.lastComponent

                if child.isSymlink {
                    let resolved = child.url.resolvingSymlinksInPath().path
                    /// The link that closes the loop; SwiftPM ignores it too.
                    if root == resolved || root.hasPrefix("\(resolved)/") { continue }
                }

                if child.isDirectory {
                    try mirror(child, at: target)
                } else {
                    try target.symlink(child)
                }
            }
        }

        /// Everything under a directory, links included and not followed.
        private static func entries(of directory: Path) -> [Path] {
            let children = (try? directory.children()) ?? []

            return children.flatMap { child -> [Path] in
                guard !child.isSymlink, child.isDirectory else { return [child] }
                return [child] + entries(of: child)
            }
        }

        static let sourcesRoot = "Sources"

        /// A package rule is built through the bundle rule that transitions it to a
        /// platform; on its own an iOS-only package would be compiled for the host,
        /// so no wildcard pattern may pick one up.
        static let manual = ["manual"]

        enum TargetKind {
            case swift
            case clang
            case binary
            case system
            /// A macro: a program the compiler loads, not a library the target links.
            case macro
            /// A command line tool the package builds.
            case executable
            /// A test suite, generated for the package the tool was pointed at.
            case test
            case unsupported(String)
        }

        /// What the target is made of, decided by the files on disk: the manifest
        /// only says `regular`.
        private func kind(of target: PackageTarget, in package: Package) throws -> TargetKind? {
            switch target.type {
            case "test":
                /// Only the package under the tool: the tests of a package a project
                /// depends on say nothing about the project.
                return package.isRoot ? .test : nil
            case "plugin":
                /// A plugin is a program SwiftPM runs, never a rule this workspace
                /// builds: a command plugin runs when someone asks for it by name,
                /// and a build tool plugin runs while the workspace is generated.
                /// Whether it ran is what the run reports.
                return nil
            case "binary":
                return .binary
            case "system":
                return .system
            case "macro":
                return .macro
            case "executable", "snippet":
                /// A tool the package builds: it has a `main`, so it links rather
                /// than being linked.
                return .executable
            default:
                break
            }

            guard sourceDirectory(of: target, in: package) != nil else {
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

        /// The rule that stands for a target.
        ///
        /// A product may carry the name of a target while grouping several of them.
        /// SwiftPM allows that; two rules cannot share one name, so the product
        /// keeps the name a consumer writes and the target's own rule is suffixed.
        func ruleName(of target: String, in package: Package) -> String {
            let grouped = package.manifest.products
                .filter { $0.kind == .library && $0.targets.count > 1 }
                .map(\.name)

            return grouped.contains(target) ? "\(target)_target" : target
        }

        /// Every file under a directory.
        ///
        /// `FileManager.subpathsOfDirectory` returns nothing when the directory
        /// itself is a symlink, and a package can point one target at another's
        /// sources that way to build a variant of it. Paths stay under the
        /// directory as named, because that is what a glob pattern is built from.
        static func walk(_ directory: Path) -> [Path] {
            var visited: Set<String> = []
            return walk(directory, visited: &visited)
        }

        private static func walk(_ directory: Path, visited: inout Set<String>) -> [Path] {
            /// A package's test fixtures can link a directory back to an ancestor,
            /// which would otherwise be walked forever.
            let resolved = directory.url.resolvingSymlinksInPath().path
            guard visited.insert(resolved).inserted else { return [] }

            let children = (try? directory.children()) ?? []
            return children.flatMap { child -> [Path] in
                child.isDirectory ? walk(child, visited: &visited) : [child]
            }
        }

        /// The target's files as paths under its source link, which is what a glob
        /// pattern is matched against.
        func relativeFiles(
            of target: PackageTarget,
            in package: Package,
            prefix: String,
            excluding exclude: Bool = true) -> [String]
        {
            guard let directory = sourceDirectory(of: target, in: package) else { return [] }
            let root = directory.normalize().string
            let files = exclude
                ? allFiles(of: target, in: package)
                : Self.walk(directory)

            return files.compactMap { file in
                let path = file.normalize().string
                guard path.hasPrefix(root) else { return nil }
                return prefix + String(path.dropFirst(root.count))
            }
        }

        /// The patterns that match at least one of the target's files.
        ///
        /// Bazel fails a glob that matches nothing, so a pattern for a file type
        /// the target does not have would break the package rather than produce an
        /// empty list.
        func matching(_ patterns: [String], _ files: [String]) -> [String] {
            patterns.filter { pattern in
                files.contains { Self.matches(pattern, $0) }
            }
        }

        /// Bazel's own glob semantics, on path segments: `**` stands for any run
        /// of segments, `*` for any part of one.
        static func matches(_ pattern: String, _ file: String) -> Bool {
            matches(
                pattern: pattern.split(separator: "/").map(String.init),
                file: file.split(separator: "/").map(String.init))
        }

        private static func matches(pattern: [String], file: [String]) -> Bool {
            guard let segment = pattern.first else { return file.isEmpty }

            if segment == "**" {
                let rest = Array(pattern.dropFirst())
                if matches(pattern: rest, file: file) { return true }
                guard !file.isEmpty else { return false }
                return matches(pattern: pattern, file: Array(file.dropFirst()))
            }

            guard let name = file.first, matches(segment: segment, name: name) else {
                return false
            }
            return matches(pattern: Array(pattern.dropFirst()), file: Array(file.dropFirst()))
        }

        private static func matches(segment: String, name: String) -> Bool {
            let parts = segment.split(separator: "*", omittingEmptySubsequences: false).map(String.init)
            guard parts.count > 1 else { return segment == name }

            var rest = Substring(name)
            for (index, part) in parts.enumerated() where !part.isEmpty {
                if index == 0 {
                    guard rest.hasPrefix(part) else { return false }
                    rest = rest.dropFirst(part.count)
                } else if index == parts.count - 1 {
                    guard rest.hasSuffix(part) else { return false }
                    rest = rest.dropLast(part.count)
                } else {
                    guard let range = rest.range(of: part) else { return false }
                    rest = rest[range.upperBound...]
                }
            }

            return true
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
                    files.append(contentsOf: Self.walk(root))
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

            /// A test target is looked for under `Tests` first, the way SwiftPM
            /// looks for it, and a plugin under `Plugins`.
            let conventional = ["Sources", "Source", "src", "srcs"]
            let candidates: [String]
            switch target.type {
            case "test":
                candidates = ["Tests"] + conventional
            case "plugin":
                candidates = ["Plugins"] + conventional
            default:
                candidates = conventional
            }

            for candidate in candidates {
                let directory = package.root + candidate + target.name
                if directory.exists { return directory }
            }

            let flat = package.root + target.name
            return flat.exists ? flat : nil
        }

        private func build(
            _ target: PackageTarget,
            in package: Package,
            prefix: String,
            generated: [String],
            resources: ResourceBundle?,
            builder: CodeBuilder)
        {
            builder.load(loadableRule: Rules.Swift.swift_library)
            builder.call(
                Rules.Swift.Call.swift_library(
                    name: ruleName(of: target.name, in: package),
                    /// SwiftPM compiles every package target with the developer
                    /// search paths, which is how a test-support library finds
                    /// XCTest.
                    always_include_developer_search_paths: true,
                    copts: copts(of: target).nonEmpty,
                    module_name: Self.moduleName(target.name),
                    /// Which targets `package` visibility reaches: every target of
                    /// the same package, which is what the name identifies.
                    package_name: package.manifest.name,
                    plugins: plugins(of: target, in: package).nonEmpty.map { macros in
                        .build { macros }
                    },
                    srcs: Starlark.glob(
                        matching(
                            sources(of: target, prefix: prefix, extensions: ["swift"]),
                            relativeFiles(of: target, in: package, prefix: prefix))
                            + generated
                            + (resources?.accessors ?? []),
                        exclude: excluded(target, prefix: prefix)),
                    deps: deps(of: target, in: package).nonEmpty.map { labels in
                        .build { labels }
                    },
                    data: resources.map { bundle in
                        .build { [Starlark.Label.named(bundle.label)] }
                    },
                    linkopts: linkopts(of: target).nonEmpty,
                    tags: Self.manual,
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
        ///
        /// Documentation catalogues are excluded on top of that: SwiftPM ignores a
        /// `.docc` directory, and the sample code inside one does not compile —
        /// it is written against `PackageDescription`.
        func excluded(_ target: PackageTarget, prefix: String) -> [String] {
            target.exclude.flatMap { excluded -> [String] in
                Path(excluded).extension == nil
                    ? ["\(prefix)/\(excluded)/**"]
                    : ["\(prefix)/\(excluded)"]
            } + Self.ignoredExtensions.map { "\(prefix)/**/*.\($0)/**" }
        }

        /// Directory types SwiftPM's file rules ignore.
        static let ignoredExtensions = ["docc", "xcprivacy"]

        /// The macros a target loads: a macro target is a program the compiler
        /// runs, so it belongs in `plugins` rather than in `deps`.
        func plugins(of target: PackageTarget, in package: Package) -> [Starlark.Label] {
            let macros = package.manifest.targets.filter { other in
                if case .macro = kinds[package.directory]?[other.name] { return true }
                return false
            }.map(\.name)

            let names = target.dependencies.compactMap { dependency -> String? in
                switch dependency.kind {
                case .target(let name), .byName(let name):
                    return macros.contains(name) ? name : nil
                case .product:
                    return nil
                }
            }

            return Set(names).sorted().map { name in
                Starlark.Label.named(":\(ruleName(of: name, in: package))")
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
                    guard localTargets.contains(name), !isMacro(name, in: package) else { return nil }
                    return ":\(ruleName(of: name, in: package))"
                case .byName(let name):
                    if localTargets.contains(name) {
                        guard !isMacro(name, in: package) else { return nil }
                        return ":\(ruleName(of: name, in: package))"
                    }
                    if localProducts[name] != nil { return ":\(name)" }
                    return label(product: name, package: nil, from: package)
                case .product(let name, let packageName):
                    return label(product: name, package: packageName, from: package)
                }
            }

            return Array(Set(labels)).sorted().map(Starlark.Label.named)
        }

        private func isMacro(_ target: String, in package: Package) -> Bool {
            if case .macro = kinds[package.directory]?[target] { return true }
            return false
        }

        /// A product of another package is reached through the facade, so the label
        /// does not depend on how that package's rules are generated.
        private func label(product: String, package name: String?, from package: Package) -> String? {
            guard let owner = self.package(ofProduct: product, package: name, from: package) else {
                Log.codeGenerate.warning("""
                No package for product \(product, privacy: .public) \
                required by \(package.directory, privacy: .public)
                """)
                return nil
            }

            return "//\(PluginSwiftPM.packagesDirectory)/\(owner.directory):\(product)"
        }

        /// Which package declares a product: the one the dependency names, or the
        /// one whose identity matches.
        private func package(
            ofProduct product: String,
            package name: String?,
            from package: Package) -> Package?
        {
            let identities = [name, product].compactMap { $0 }
                + package.manifest.dependencies.map(\.identity)

            for identity in identities {
                guard let directory = workspace.directoryByIdentity[identity.lowercased()] else { continue }
                return workspace.packages.first { $0.directory == directory }
            }

            return nil
        }

        private func build(
            _ product: PackageProduct,
            emitted: Set<String>,
            package: Package,
            builder: CodeBuilder)
        {
            switch product.kind {
            case .library:
                break
            case .executable:
                buildExecutable(product, emitted: emitted, package: package, builder: builder)
                return
            case .plugin:
                return
            }

            /// A macro is not part of a product a consumer links: it is loaded by
            /// the compiler of whatever declares the macro, inside its own package.
            let targets = product.targets.filter { target in
                emitted.contains(target) && !isMacro(target, in: package)
            }
            guard !targets.isEmpty else { return }

            /// A product of one target is that target under another name; several
            /// targets are a group that exports all of them.
            if targets.count == 1, let target = targets.first {
                guard target != product.name else { return }

                builder.call(
                    Rules.Builtin.Call.alias(
                        name: product.name,
                        actual: .named(":\(ruleName(of: target, in: package))"),
                        tags: Self.manual,
                        visibility: .public))
                return
            }

            builder.load(loadableRule: Rules.Swift.swift_library_group)
            builder.call(
                Rules.Swift.Call.swift_library_group(
                    name: product.name,
                    deps: .build {
                        targets.sorted().map { target in
                            Starlark.Label.named(":\(ruleName(of: target, in: package))")
                        }
                    },
                    tags: Self.manual,
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
