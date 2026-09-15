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

    func embeddedExtensionTargetNames(project: Project) -> [String] {
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
        /// Every dependency is compiled and linked against as a library; a bundle
        /// that embeds one of them passes it in `frameworks` as well, and rules_apple
        /// then keeps those symbols out of the embedding binary.
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

    /// Sibling frameworks Xcode copies into the bundle: the app links against the
    /// framework and loads it at runtime, so its resources stay in the framework and
    /// `Bundle(for:)` resolves there. Linking its library instead loses both.
    func embeddedFrameworkNames(project: Project) -> [String] {
        let siblings = Set(project.targets.map(\.name))

        let names = files.copyFiles.compactMap { file -> String? in
            guard file.fileType == "wrapper.framework" else { return nil }
            guard let component = file.name ?? file.path else { return nil }
            return Path(component).lastComponentWithoutExtension
        }

        return Array(Set(names).intersection(siblings)).sorted()
    }

    /// The bundle that embeds this target, if any: an embedded bundle inherits the
    /// parent's version and identifier prefix, which rules_apple insists on.
    ///
    /// `nil` when two applications embed it: one bundle cannot carry both prefixes,
    /// so the target stays a library linked into each of them, the way it was before
    /// it was recognized as embedded at all.
    func embeddingBundle(project: Project?) -> Target? {
        guard let project else { return nil }

        let parents = project.targets.filter { parent in
            parent.name != name
                && (parent.embeddedFrameworkNames(project: project).contains(name)
                    || parent.embeddedExtensionTargetNames(project: project).contains(name))
        }

        let applications = parents.filter { parent in
            parent.productType == "com.apple.product-type.application"
        }
        guard applications.count <= 1 else { return nil }

        /// A framework embedded in both the app and one of its extensions follows
        /// the app: that is what rules_apple compares everything to.
        return applications.first ?? parents.first
    }

    /// `PRODUCT_BUNDLE_IDENTIFIER`, prefixed with the identifier of the bundle that
    /// embeds this one.
    ///
    /// Apple requires the prefix and rules_apple enforces it; Xcode does not, so a
    /// framework in the same project routinely carries an unrelated identifier.
    func bundleIdentifier(project: Project?) -> String? {
        /// rules_apple substitutes nothing here, so a reference Xcode would have
        /// expanded — UTM spells every identifier
        /// `$(PRODUCT_BUNDLE_PREFIX:default=com.utmapp).X` — is expanded first.
        let own = prefer(\.metadata.bundleID)
            .map { identifier in
                identifier.resolvingBuildSettingReferences(with: selectedSettings, reserved: [])
            }
            .flatMap { identifier in
                identifier.contains("$") ? nil : identifier
            }

        guard
            let parent = embeddingBundle(project: project),
            let parentID = parent.bundleIdentifier(project: project),
            let own, !own.hasPrefix("\(parentID).")
        else {
            return own
        }

        let suffix = own.components(separatedBy: ".").last ?? name
        return "\(parentID).\(suffix)"
    }

    func embeddedFrameworks(project: Project) -> [Starlark.Label] {
        embeddedFrameworkNames(project: project)
            .filter { target in
                project.target(named: target)?.embeddingBundle(project: project)?.name == name
            }
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)")
            }
    }

    func embeddedExtensions(project: Project) -> [Starlark.Label] {
        embeddedExtensionTargetNames(project: project)
            .sorted()
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)")
            }
    }
}
