import Foundation
import PathKit
import Starlark

typealias Project = XCode2.XCode.Project
typealias Target = XCode2.XCode.Target
typealias BuildSettings = XCode2.XCode.BuildSettings
typealias File = XCode2.XCode.File
typealias RemotePackage = XCode2.XCode.RemotePackage
typealias LocalPackage = XCode2.XCode.LocalPackage
typealias PackageProductDependency = XCode2.XCode.PackageProductDependency
typealias DeviceFamily = XCode2.XCode.DeviceFamily

extension Dictionary where Key == String, Value == BuildSettings {
    func select<T: Hashable>(_ keypath: KeyPath<Value, T>) -> Starlark.Select<T> {
        let values = map { _, setting in
            setting[keyPath: keypath]
        }

        if Set(values).count == 1, let first = first?.value[keyPath: keypath] {
            return .same(first)
        }

        let result: [Starlark.Label: T] = reduce(into: [:]) { partialResult, entry in
            partialResult[.config(entry.key)] = entry.value[keyPath: keypath]
        }
        return .various(result)
    }
}

extension Project {
    fileprivate func target(named name: String) -> Target? {
        targets.first { $0.name == name }
    }
}

extension Target {
    func select<T: Hashable>(_ keyPath: KeyPath<BuildSettings, T>, project _: Project) -> Starlark.Select<T> {
        configs.select(keyPath)
    }

    fileprivate func isExtensionTarget(_ name: String, in project: Project) -> Bool {
        guard let productType = project.target(named: name)?.productType else { return false }
        return productType.contains("app-extension")
    }

    /// A product that carries its own entry point or is a standalone bundle cannot be
    /// linked into another target: Xcode embeds it instead, and linking it would
    /// duplicate `main`.
    fileprivate func isLinkableTarget(_ name: String, in project: Project) -> Bool {
        guard let productType = project.target(named: name)?.productType else { return true }

        /// A test bundle is the exception: Xcode loads it into the host process, so
        /// the host's code has to be reachable. Bazel has no `-bundle_loader`
        /// equivalent for a logic test, so the host is linked in.
        if isTest, productType == "com.apple.product-type.application" {
            return true
        }

        switch productType {
        case "com.apple.product-type.application",
             "com.apple.product-type.tool",
             "com.apple.product-type.bundle.unit-test",
             "com.apple.product-type.bundle.ui-testing":
            return false
        default:
            return !productType.contains("app-extension")
        }
    }

    fileprivate func linkedTargetDependencyNames(project: Project) -> [String] {
        dependencies.targets.filter { isLinkableTarget($0, in: project) }
    }

    fileprivate func embeddedExtensionTargetNames(project: Project) -> [String] {
        dependencies.targets.filter { isExtensionTarget($0, in: project) }
    }

    var frameworksLibrary: [Starlark.Label] {
        let targetLabels = dependencies.targets
            .sorted()
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)_library")
            }
        let frameworkLabels = dependencies.frameworks
            .sorted()
            .map(Starlark.Label.named)
        return Array(Set(targetLabels + frameworkLabels)).sorted { $0.text < $1.text }
    }

    var frameworks: [Starlark.Label] {
        let targetLabels = dependencies.targets
            .sorted()
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)")
            }
        let frameworkLabels = dependencies.frameworks
            .sorted()
            .map(Starlark.Label.named)
        return Array(Set(targetLabels + frameworkLabels)).sorted { $0.text < $1.text }
    }

    func linkedFrameworksLibrary(project: Project) -> [Starlark.Label] {
        let targetLabels = linkedTargetDependencyNames(project: project)
            .sorted()
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)_library")
            }
        let frameworkLabels = dependencies.frameworks
            .sorted()
            .map(Starlark.Label.named)
        return Array(Set(targetLabels + frameworkLabels)).sorted { $0.text < $1.text }
    }

    func linkedFrameworks(project: Project) -> [Starlark.Label] {
        let targetLabels = linkedTargetDependencyNames(project: project)
            .sorted()
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)")
            }
        let frameworkLabels = dependencies.frameworks
            .sorted()
            .map(Starlark.Label.named)
        return Array(Set(targetLabels + frameworkLabels)).sorted { $0.text < $1.text }
    }

    func embeddedExtensions(project: Project) -> [Starlark.Label] {
        embeddedExtensionTargetNames(project: project)
            .sorted()
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)")
            }
    }
}
