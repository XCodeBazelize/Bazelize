import Foundation
import PathKit
import Starlark

typealias Project = Xcode.Project
typealias Target = Xcode.Target
typealias BuildSettings = Xcode.BuildSettings
typealias File = Xcode.File
typealias RemotePackage = Xcode.RemotePackage
typealias LocalPackage = Xcode.LocalPackage
typealias PackageProductDependency = Xcode.PackageProductDependency
typealias DeviceFamily = Xcode.DeviceFamily

extension Dictionary where Key == String, Value == BuildSettings {
    func select<T: Hashable>(_ keypath: KeyPath<Value, T>) -> Starlark.Select<T> {
        let values = map { _, setting in
            setting[keyPath: keypath]
        }

        if Set(values).count == 1, let first = first?.value[keyPath: keypath] {
            return .same(first)
        }

        /// Every configuration of the target is a key, and `//:mode` takes no
        /// value that is not one of them, so nothing falls through.
        let result: [Starlark.Label: T] = reduce(into: [:]) { partialResult, entry in
            partialResult[.config(entry.key)] = entry.value[keyPath: keypath]
        }
        return .exhaustive(result)
    }
}

extension Target {
    func select<T: Hashable>(_ keyPath: KeyPath<BuildSettings, T>, project _: borrowing Project) -> Starlark.Select<T> {
        configs.select(keyPath)
    }

    private func productTypeOfTarget(named name: String, in project: borrowing Project) -> Xcode.ProductType? {
        project.withTarget(named: name, { $0.productType }) ?? nil
    }

    private func isExtensionTarget(_ name: String, in project: borrowing Project) -> Bool {
        productTypeOfTarget(named: name, in: project)?.isAppExtension ?? false
    }

    /// A product that carries its own entry point or is a standalone bundle cannot be
    /// linked into another target: Xcode embeds it instead, and linking it would
    /// duplicate `main`.
    private func isLinkableTarget(_ name: String, in project: borrowing Project) -> Bool {
        guard let productType = project.withTarget(named: name, { $0.productType }) ?? nil else { return true }

        /// A test bundle is the exception: Xcode loads it into the host process, so
        /// the host's code has to be reachable. Bazel has no `-bundle_loader`
        /// equivalent for a logic test, so the host is linked in.
        if isTest, productType == .application {
            return true
        }

        switch productType {
        case .application, .onDemandInstallCapableApplication, .messagesApplication, .watch2App,
             .watch2AppContainer, .watch2Extension, .commandLineTool, .bundle, .unitTestBundle, .uiTestBundle:
            return false
        default:
            return !productType.isAppExtension
        }
    }

    private func linkedTargetDependencyNames(project: borrowing Project) -> [String] {
        dependencies.targets.filter { target in
            isLinkableTarget(target, in: project) && project.withTarget(named: target, { $0.hasSources }) != false
        }
    }

    func embeddedExtensionTargetNames(project: borrowing Project) -> [String] {
        dependencies.targets.filter { isExtensionTarget($0, in: project) }
    }

    /// The sticker packs among the extensions: only an iMessage app takes one.
    func embeddedStickerPackNames(project: borrowing Project) -> [String] {
        embeddedExtensionTargetNames(project: project)
            .filter { productTypeOfTarget(named: $0, in: project) == .stickerPack }
            .sorted()
    }

    /// The App Clips the application embeds in `AppClips`.
    func embeddedAppClips(project: borrowing Project) -> [Starlark.Label] {
        dependencies.targets
            .filter { productTypeOfTarget(named: $0, in: project) == .onDemandInstallCapableApplication }
            .filter { project.withTarget(named: $0, { $0.isGenerated }) == true }
            .sorted()
            .map { Starlark.Label.named("//Targets/\($0):\($0)") }
    }

    /// The WatchKit extensions a watchOS 2 app carries.
    func watchKitExtensionNames(project: borrowing Project) -> [String] {
        dependencies.targets
            .filter { productTypeOfTarget(named: $0, in: project) == .watch2Extension }
            .sorted()
    }

    /// The watch app an iOS app carries in `Watch/`: a single-target watchOS
    /// application, or a watchOS 2 app. rules_apple takes one; any other is
    /// left out and named.
    func embeddedWatchApplication(project: borrowing Project, _ kit: Kit) -> Starlark.Label? {
        let watchApplications = dependencies.targets
            .filter { target in
                let kind = project.withTarget(named: target) { ($0.productType, $0.platformSDK, $0.isGenerated) }
                guard let (productType, sdk, isGenerated) = kind, isGenerated else { return false }
                return productType == .watch2App || (productType == .application && sdk == .watchOS)
            }
            .sorted()

        for extra in watchApplications.dropFirst() {
            kit.note("""
            \(name) embeds the watch app \(extra), which is left out of it: an iOS app carries one watch app, \
            and it already carries \(watchApplications[0]).
            """)
        }
        return watchApplications.first.map { Starlark.Label.named("//Targets/\($0):\($0)") }
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

    func linkedFrameworksLibrary(project: borrowing Project) -> [Starlark.Label] {
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

    func linkedFrameworks(project: borrowing Project) -> [Starlark.Label] {
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
    func embeddedFrameworkNames(project: borrowing Project) -> [String] {
        let siblings = Set(project.targetNames)

        let names = files.copyFiles.compactMap { file -> String? in
            guard file.fileType == "wrapper.framework" else { return nil }
            guard let component = file.name ?? file.path else { return nil }
            return Path(component).lastComponentWithoutExtension
        }

        return Array(Set(names).intersection(siblings)).sorted().filter { name in
            project.withTarget(named: name, { $0.hasSources }) == true
        }
    }

    /// The position in `project.targets` of the bundle that embeds this target, if
    /// any: an embedded bundle inherits the parent's version and identifier prefix,
    /// which rules_apple insists on.
    ///
    /// `nil` when two applications embed it: one bundle cannot carry both prefixes,
    /// so the target stays a library linked into each of them, the way it was before
    /// it was recognized as embedded at all.
    func embeddingBundleIndex(project: borrowing Project) -> Int? {
        let parents = project.targets.indices.filter { index in
            project.targets[index].name != name
                && (project.targets[index].embeddedFrameworkNames(project: project).contains(name)
                    || project.targets[index].embeddedExtensionTargetNames(project: project).contains(name))
        }

        let applications = parents.filter { index in
            project.targets[index].productType == .application
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
    func bundleIdentifier(project: borrowing Project) -> String? {
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
            let parent = embeddingBundleIndex(project: project),
            let parentID = project.targets[parent].bundleIdentifier(project: project),
            let own, !own.hasPrefix("\(parentID).")
        else {
            return own
        }

        let suffix = own.components(separatedBy: ".").last ?? name
        return "\(parentID).\(suffix)"
    }

    func embeddedFrameworks(project: borrowing Project) -> [Starlark.Label] {
        embeddedFrameworkNames(project: project)
            .filter { target in
                let parent = project.withTarget(named: target) { $0.embeddingBundleIndex(project: project) } ?? nil
                return parent.map { project.targets[$0].name } == name
            }
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)")
            }
    }

    /// The extensions an application's `extensions` takes. A sticker pack is not
    /// one of them: rules_apple embeds it only in an iMessage app.
    func embeddedExtensions(project: borrowing Project) -> [Starlark.Label] {
        embeddedExtensionTargetNames(project: project)
            .filter { productTypeOfTarget(named: $0, in: project) != .stickerPack }
            .filter { project.withTarget(named: $0, { $0.hasSources }) == true }
            .sorted()
            .map { target in
                Starlark.Label.named("//Targets/\(target):\(target)")
            }
    }
}
