//
//  SwiftPM+Generator+Dependency.swift
//
//
//  What a target links, and the labels it reaches another package through.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// What the target links. A SwiftPM dependency condition becomes a
    /// `select`, so the consuming build decides whether that label exists.
    func deps(of target: SwiftPM.PackageTarget, in package: SwiftPM.Package) -> Starlark.Value? {
        let localTargets = Set(package.manifest.targets.map(\.name))
        let localProducts = Dictionary(
            package.manifest.products.map { ($0.name, $0) },
            uniquingKeysWith: { first, _ in first })

        func dependencyLabels(_ dependency: SwiftPM.TargetDependency) -> [String] {
            switch dependency.kind {
            case .target(let name):
                guard localTargets.contains(name), !isMacro(name, in: package) else { return [] }
                return [":\(ruleName(of: name, in: package))"]
            case .byName(let name):
                if localTargets.contains(name) {
                    guard !isMacro(name, in: package) else { return [] }
                    return [":\(ruleName(of: name, in: package))"]
                }
                if localProducts[name] != nil { return [":\(name)"] }
                return label(product: name, package: nil, from: package).map { [$0] } ?? []
            case .product(let name, let packageName):
                /// An aliased module is compiled under the name this package
                /// calls it, so what is linked is that rule rather than the
                /// product the module is part of.
                if !dependency.moduleAliases.isEmpty {
                    return aliasLabels(
                        of: dependency.moduleAliases,
                        product: name,
                        package: packageName,
                        from: package)
                }
                return label(product: name, package: packageName, from: package).map { [$0] } ?? []
            }
        }

        return conditionalDependencies(
            of: target,
            in: package,
            labels: dependencyLabels)
    }

    /// Labels are unconditional only when their SwiftPM dependency is.
    /// Platform, trait and configuration dimensions are kept as selectors
    /// so the configuration that compiles the consumer decides.
    func conditionalDependencies(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        labels: (SwiftPM.TargetDependency) -> [String])
        -> Starlark.Value?
    {
        var always: Set<String> = []
        var conditions: [String] = []
        var byCondition: [String: Set<String>] = [:]

        for dependency in target.dependencies {
            let labels = labels(dependency)
            guard !labels.isEmpty else { continue }

            guard let condition = settingCondition(dependency.condition, in: package) else {
                always.formUnion(labels)
                continue
            }

            if byCondition[condition] == nil { conditions.append(condition) }
            byCondition[condition, default: []].formUnion(labels)
        }

        return conditionalValue(
            always.sorted(),
            conditional: conditions.map { ($0, (byCondition[$0] ?? []).sorted()) })
    }

    /// A product of another package is reached through the facade, so the label
    /// does not depend on how that package's rules are generated.
    private func label(product: String, package name: String?, from package: SwiftPM.Package) -> String? {
        guard let owner = self.package(ofProduct: product, package: name, from: package) else {
            Log.codeGenerate.warning("""
            No package for product \(product, privacy: .public) \
            required by \(package.directory, privacy: .public)
            """)
            return nil
        }

        return "//\(PluginSwiftPM.packagesDirectory)/\(owner.directory):\(product)"
    }

    /// What an aliasing consumer links: the aliased module of every target
    /// the product holds, plus each target it did not rename.
    private func aliasLabels(
        of aliases: [String: String],
        product: String,
        package name: String?,
        from package: SwiftPM.Package) -> [String]
    {
        guard let owner = self.package(ofProduct: product, package: name, from: package) else {
            Log.codeGenerate.warning("""
            No package for product \(product, privacy: .public) \
            required by \(package.directory, privacy: .public)
            """)
            return []
        }

        let directory = "//\(PluginSwiftPM.packagesDirectory)/\(owner.directory)"
        let targets = owner.manifest.products
            .first { $0.name == product }?
            .targets ?? []

        return targets.map { target in
            guard let alias = aliases[target] else {
                return "\(directory):\(ruleName(of: target, in: owner))"
            }
            return "\(directory):\(Self.aliasRuleName(of: target, as: alias))"
        }
    }

    /// Every alias any package asks for, filed under the package that owns
    /// the module: that package's `BUILD` is where the aliased rule goes.
    func collectModuleAliases() {
        for package in workspace.packages {
            for target in package.manifest.targets {
                for dependency in target.dependencies {
                    guard
                        !dependency.moduleAliases.isEmpty,
                        case .product(let product, let owner) = dependency.kind,
                        let source = self.package(ofProduct: product, package: owner, from: package)
                    else {
                        continue
                    }

                    for (module, alias) in dependency.moduleAliases {
                        moduleAliases[source.directory, default: [:]][module, default: []].insert(alias)
                    }
                }
            }
        }
    }

    /// Which package declares a product. The name a dependency writes is the
    /// one its own manifest gave that package — SwiftPM's identity, the
    /// dependency's `name:`, or the manifest's own name — so all three are
    /// tried before falling back to the single package declaring the product.
    /// Never guess from an unrelated dependency merely because it appears
    /// first in the manifest.
    private func package(
        ofProduct product: String,
        package name: String?,
        from consumer: SwiftPM.Package) -> SwiftPM.Package?
    {
        if let name {
            let identities = [name] + consumer.manifest.dependencies
                .filter { $0.name?.lowercased() == name.lowercased() }
                .map(\.identity)

            for identity in identities {
                guard
                    let directory = workspace.directoryByIdentity[identity.lowercased()],
                    let owner = workspace.packages.first(where: { $0.directory == directory })
                else {
                    continue
                }
                return owner
            }
        }

        let owners = workspace.packages.filter { candidate in
            candidate.manifest.products.contains { $0.name == product }
        }
        return owners.count == 1 ? owners[0] : nil
    }
}
