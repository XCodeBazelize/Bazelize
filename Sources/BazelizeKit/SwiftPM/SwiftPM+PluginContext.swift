//
//  SwiftPM+PluginContext.swift
//
//
//  The package graph a plugin is handed.
//

import Foundation
@preconcurrency import PathKit

extension SwiftPM {
    /// Builds what a plugin is told about the package it is running for.
    ///
    /// A plugin reads the target it was asked about — its sources, its name, the
    /// directory it lives in — and the package around it. That is what this
    /// assembles, in the shape SwiftPM's protocol spells: every path interned so
    /// a graph of files repeats no directory.
    struct PluginContextBuilder {
        // MARK: Lifecycle

        init(package: Package, generator: Generator) {
            self.package = package
            self.generator = generator
        }

        // MARK: Internal

        /// Adds the package and every target in it, and answers which id the
        /// target being asked about has.
        mutating func add(package: Package, asking target: PackageTarget) throws -> Int {
            let directoryId = add(path: package.root.absolute().string)

            var targetIds: [Int] = []
            for (index, candidate) in package.manifest.targets.enumerated() {
                indexByTarget[candidate.name] = index
                targetIds.append(index)
            }

            targets = try package.manifest.targets.map { candidate in
                try wire(candidate, in: package, sources: candidate.name == target.name)
            }

            products = package.manifest.products.map { product in
                let ids = product.targets.compactMap { indexByTarget[$0] }
                return .init(
                    name: product.name,
                    targetIds: ids,
                    info: product.kind == .executable
                        ? .executable(mainTargetId: ids.first ?? 0)
                        : .library)
            }

            packages = [
                .init(
                    identity: package.identity,
                    displayName: package.manifest.name,
                    directoryId: directoryId,
                    origin: package.isRoot ? .root : .local(pathId: directoryId),
                    toolsVersion: Self.version(package.manifest.toolsVersion),
                    dependencies: [],
                    productIds: Array(products.indices),
                    targetIds: targetIds),
            ]

            guard let id = indexByTarget[target.name] else {
                throw PluginError.undecodable("the target asked about is not in its own package")
            }

            return id
        }

        /// Interns a path, answering the id the wire refers to it by.
        mutating func add(path: String) -> Int {
            if let id = idByPath[path] { return id }

            let id = paths.count
            paths.append(.init(baseURLId: nil, subpath: path))
            idByPath[path] = id
            return id
        }

        func context(workDirectoryId: Int, tools: [String: PluginWire.Tool]) -> PluginWire.InputContext {
            .init(
                paths: paths,
                targets: targets,
                products: products,
                packages: packages,
                xcodeTargets: [],
                xcodeProjects: [],
                pluginWorkDirId: workDirectoryId,
                toolSearchDirIds: [],
                accessibleTools: tools)
        }

        // MARK: Private

        private let package: Package
        private let generator: Generator

        private var paths: [PluginWire.URLNode] = []
        private var idByPath: [String: Int] = [:]
        private var indexByTarget: [String: Int] = [:]
        private var targets: [PluginWire.Target] = []
        private var products: [PluginWire.Product] = []
        private var packages: [PluginWire.Package] = []

        /// `6.0.0` as the three numbers the wire wants.
        private static func version(_ value: String) -> PluginWire.Package.ToolsVersion {
            let parts = value.split(separator: ".").compactMap { Int($0) }
            return .init(
                major: parts.count > 0 ? parts[0] : 5,
                minor: parts.count > 1 ? parts[1] : 9,
                patch: parts.count > 2 ? parts[2] : 0)
        }

        /// One target, with its files listed only for the target being asked
        /// about: a plugin reads those, and walking every target of a package to
        /// tell it about files it never looks at is work for nothing.
        private mutating func wire(
            _ target: PackageTarget,
            in package: Package,
            sources listed: Bool) throws -> PluginWire.Target
        {
            let directory = generator.sourceDirectory(of: target, in: package) ?? package.root
            let directoryId = add(path: directory.absolute().string)

            let dependencies: [PluginWire.Target.Dependency] = target.dependencies.compactMap { dependency in
                switch dependency.kind {
                case .target(let name), .byName(let name):
                    return indexByTarget[name].map { .target($0) }
                case .product:
                    return nil
                }
            }

            let files: [PluginWire.File] = listed
                ? Generator.walk(directory).map { file in
                    .init(
                        basePathId: directoryId,
                        name: file.absolute().string.delete(prefix: directory.absolute().string + "/") ?? file
                            .lastComponent,
                        type: Self.type(of: file))
                }
                : []

            return .init(
                name: target.name,
                directoryId: directoryId,
                dependencies: dependencies,
                info: Self.info(of: target, module: Generator.moduleName(target.name), sources: files))
        }

        private static func info(
            of target: PackageTarget,
            module: String,
            sources: [PluginWire.File]) -> PluginWire.TargetInfo
        {
            switch target.type {
            case "binary":
                return .binary(artifactId: 0)
            case "system":
                return .system
            default:
                return .swift(module: module, kind: Self.kind(of: target), sources: sources)
            }
        }

        /// What SwiftPM calls the kind of a source module.
        private static func kind(of target: PackageTarget) -> String {
            switch target.type {
            case "executable", "snippet":
                return "executable"
            case "test":
                return "test"
            case "macro":
                return "macro"
            default:
                return "generic"
            }
        }

        private static func type(of file: Path) -> String {
            let `extension` = file.extension ?? ""
            if Generator.headerExtensions.contains(`extension`) { return "header" }
            if `extension` == "swift" || Generator.compileExtensions.contains(`extension`) { return "source" }
            return "resource"
        }
    }
}
