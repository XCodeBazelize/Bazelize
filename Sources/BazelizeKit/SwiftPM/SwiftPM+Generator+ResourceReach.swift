//
//  SwiftPM+Generator+ResourceReach.swift
//
//
//  Which library targets end up inside a program Bazel runs.
//

import Foundation

extension SwiftPM.Generator {
    /// A library target identified across packages.
    struct TargetKey: Hashable {
        let package: String
        let target: String
    }

    /// The targets a `swift_binary` links.
    ///
    /// An Apple bundle embeds a dependency's resource bundle through the
    /// resource providers rules_apple collects. A plain executable has no
    /// bundler: whatever its libraries need at runtime has to be in its
    /// runfiles, so the libraries a program reaches are the ones whose bundles
    /// must be materialized rather than only propagated.
    func targetsReachedByExecutables() -> Set<TargetKey> {
        var reached: Set<TargetKey> = []
        var pending: [TargetKey] = workspace.packages.flatMap { package in
            package.manifest.targets
                .filter { $0.type == "executable" }
                .map { TargetKey(package: package.directory, target: $0.name) }
        }

        while let key = pending.popLast() {
            guard
                let package = workspace.packages.first(where: { $0.directory == key.package }),
                let target = package.manifest.targets.first(where: { $0.name == key.target })
            else {
                continue
            }

            for dependency in target.dependencies {
                for next in targets(of: dependency, from: package) where reached.insert(next).inserted {
                    pending.append(next)
                }
            }
        }

        return reached
    }

    /// What one dependency of a target names, as the targets behind it.
    private func targets(
        of dependency: SwiftPM.TargetDependency,
        from package: SwiftPM.Package) -> [TargetKey]
    {
        switch dependency.kind {
        case let .target(name):
            return [TargetKey(package: package.directory, target: name)]
        case let .byName(name):
            /// A target of this package wins over a product of the same name,
            /// which is how SwiftPM resolves the shorthand.
            if package.manifest.targets.contains(where: { $0.name == name }) {
                return [TargetKey(package: package.directory, target: name)]
            }
            return targets(ofProduct: name, package: nil, from: package)
        case let .product(name, owner):
            return targets(ofProduct: name, package: owner, from: package)
        }
    }

    /// The targets a product holds, in the package that declares it.
    private func targets(
        ofProduct product: String,
        package name: String?,
        from consumer: SwiftPM.Package) -> [TargetKey]
    {
        guard let owner = package(ofProduct: product, package: name, from: consumer) else { return [] }

        return owner.manifest.products
            .filter { $0.name == product }
            .flatMap(\.targets)
            .map { TargetKey(package: owner.directory, target: $0) }
    }
}
