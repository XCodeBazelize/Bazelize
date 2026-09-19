import Foundation
import PathKit
import XcodeProj

// MARK: - TargetLoader

struct TargetLoader {
    let native: PBXNativeTarget
    unowned let project: ProjectLoader
    let preferConfig: String?
    let configList: ConfigListLoader
    let mergedConfig: [String: Xcode.BuildSettings]

    init(native: PBXNativeTarget, project: ProjectLoader, defaultConfigList: ConfigListLoader?) {
        self.native = native
        self.project = project
        preferConfig = project.preferConfig
        configList = ConfigListLoader(native: native.buildConfigurationList, sourceRoot: project.workspacePath)
        /// Xcode's built-in settings never appear in the project file, but build
        /// settings reference them freely (`INFOPLIST_FILE = $(SRCROOT)/...`).
        let workspace = project.workspacePath.string
        mergedConfig = configList.merge(defaultConfigList).mapValues { settings in
            settings
                .with(overrides: [
                    "TARGET_NAME": native.name,
                    "PROJECT_NAME": project.name,
                    "SRCROOT": workspace,
                    "SOURCE_ROOT": workspace,
                    "PROJECT_DIR": workspace,
                ])
                /// What the toolchain answers for, and the configuration being
                /// built — defaults, because a project that states one of them
                /// itself means it: iina writes `CONFIGURATION` into an xcconfig.
                ///
                /// The platform is resolved rather than read: `SDKROOT` is
                /// optional, and `auto` names no SDK at all.
                .with(defaults: Toolchain
                    .settings(sdk: settings.platform.resolvedSDK?.rawValue)
                    .merging(["CONFIGURATION": settings.name]) { _, new in new })
        }
    }

    var name: String { native.name }

    var model: Xcode.Target {
        let buildPhases = native.buildPhases.map(Xcode.BuildPhase.init)
        let synchronizedFiles = synchronizedGroupFiles

        let sourceFiles = unique(
            fileModels(from: sourceBuildFiles, buildPhase: .sources) +
                synchronizedFiles.filter { file in
                    file.category == .source
                }.map(\.file)) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }
        let headerFiles = unique(
            fileModels(from: headerBuildFiles, buildPhase: .headers) +
                packageHeaders +
                synchronizedFiles.filter { file in
                    file.category == .header
                }.map(\.file)) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }
        let resourceFiles = unique(
            fileModels(from: resourceBuildFiles, buildPhase: .resources) +
                synchronizedFiles.filter { file in
                    file.category == .resource
                }.map(\.file)) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }
        let frameworkFiles = fileModels(from: frameworkBuildFiles, buildPhase: .frameworks)
        let copyFiles = fileModels(from: copyBuildFiles, buildPhase: .copyFiles)

        let knownPaths = Set(
            (sourceFiles + headerFiles + resourceFiles + frameworkFiles + copyFiles)
                .compactMap(\.path))

        let otherFiles = project.packageFiles(targetName: name)
            .filter { file in
                guard let path = file.relativePath else { return false }
                return !knownPaths.contains(path)
            }
            .map { $0.file(buildPhase: nil, compilerFlags: nil, attributes: []) } +
            synchronizedFiles.filter { file in
                file.category == .other && !knownPaths.contains(file.file.path ?? "")
            }.map(\.file)

        return Xcode.Target(
            name: name,
            productName: native.productName,
            productType: native.productType?.rawValue,
            preferConfig: preferConfig,
            configs: mergedConfig,
            metadata: metadata,
            buildPhases: buildPhases,
            files: .init(
                sources: sourceFiles,
                headers: headerFiles,
                resources: resourceFiles,
                frameworks: frameworkFiles,
                copyFiles: copyFiles,
                others: unique(otherFiles) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }),
            dependencies: dependencies)
    }

    private var metadata: Xcode.TargetMetadata {
        let settings = selectedConfig ?? .init(name: "", setting: [:])

        return .init(
            bundleID: settings.metadata.bundleID,
            moduleName: settings.metadata.moduleName ?? settings.metadata.productName,
            infoPlist: settings.plist.infoPlist,
            entitlements: settings.metadata.codeSignEntitlements,
            deploymentTargets: settings.platform.deploymentTargets,
            codeSign: .init(
                developmentTeam: settings.metadata.developmentTeam,
                codeSignStyle: settings.metadata.codeSignStyle,
                codeSignIdentity: settings.metadata.codeSignIdentity))
    }

    private var dependencies: Xcode.Dependencies {
        let declaredDependencies = native.dependencies.compactMap { dependency in
            dependency.target?.name ?? dependency.name
        }

        /// A target can link a sibling target's framework through the Frameworks
        /// phase without declaring a target dependency; Xcode resolves it implicitly.
        let implicitDependencies = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard let identity = wrapped.frameworkIdentity else { return nil }
            guard identity != name, project.targetNames.contains(identity) else { return nil }
            return identity
        }

        let targetDependencies = declaredDependencies + implicitDependencies
        let targetDependencyIdentities = Set(targetDependencies)

        let frameworks = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard !wrapped.isSDKFramework, !wrapped.isSDKDylib else { return nil }

            if let identity = wrapped.frameworkIdentity, targetDependencyIdentities.contains(identity) {
                return nil
            }

            if
                let label = wrapped.label(buildPhase: BuildPhase.frameworks.rawValue),
                label.hasPrefix("//Prebuilt:")
            {
                /// A framework that only exists after a Carthage/CocoaPods/script
                /// bootstrap cannot be imported, and referencing it anyway leaves the
                /// generated workspace unloadable.
                guard wrapped.existsOnDisk else { return nil }
                return label
            }

            return wrapped.name
        }

        let sdkFrameworks = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard wrapped.isSDKFramework else { return nil }
            guard !(buildFile.attributes ?? []).contains("Weak") else { return nil }
            return wrapped.sdkFrameworkName
        }

        let weakSDKFrameworks = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard wrapped.isSDKFramework else { return nil }
            guard (buildFile.attributes ?? []).contains("Weak") else { return nil }
            return wrapped.sdkFrameworkName
        }

        let sdkDylibs = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            /// Only a dylib the SDK ships is linked by name; one the project carries
            /// is imported by path, like any other prebuilt binary.
            guard wrapped.isSDKDylib else { return nil }
            return wrapped.sdkDylibName ?? wrapped.name.flatMap { Path($0).lastComponentWithoutExtension }
        }

        /// Xcode references system frameworks by absolute path; only their directory
        /// matters for linking, and anything outside the default
        /// `/System/Library/Frameworks` has to be handed to the linker explicitly.
        let sdkFrameworkSearchPaths = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard wrapped.isSDKFramework, let fullPath = wrapped.fullPath, fullPath.hasPrefix("/") else {
                return nil
            }
            let directory = Path(fullPath).parent().string
            guard directory != "/System/Library/Frameworks" else { return nil }
            return directory
        }

        /// Xcode records a linked package product either on the target or on the
        /// build file in the Frameworks phase, depending on how it was added.
        let excluded = filteredProductNames
        let productDependencies = ((native.packageProductDependencies ?? []) + frameworkBuildFiles.compactMap { buildFile in
            buildFile.product
        }).filter { product in
            !excluded.contains(product.productName)
        }

        let packageProducts = unique(productDependencies) { $0.productName }.map { dependency in
            Xcode.PackageProductDependency(
                productName: dependency.productName,
                package: dependency.package?.repositoryURL,
                packagePath: project.localPackagePathByProduct[dependency.productName])
        }

        return .init(
            targets: Set(targetDependencies).sorted(),
            packageProducts: unique(packageProducts) { "\($0.productName)|\($0.package ?? "")" },
            frameworks: Set(frameworks.compactMap { $0 }).sorted(),
            sdkDylibs: Set(sdkDylibs.compactMap { $0 }).sorted(),
            sdkFrameworks: Set(sdkFrameworks.compactMap { $0 }).sorted(),
            sdkFrameworkSearchPaths: Set(sdkFrameworkSearchPaths).sorted(),
            weakSDKFrameworks: Set(weakSDKFrameworks.compactMap { $0 }).sorted())
    }

    private var selectedConfig: Xcode.BuildSettings? {
        if let prefer = project.preferConfig, let hit = mergedConfig[prefer] {
            return hit
        }
        return mergedConfig
            .sorted { $0.key < $1.key }
            .map(\.value)
            .first
    }

    private var packageHeaders: [Xcode.File] {
        project.packageFiles(targetName: name)
            .filter { file in
                guard let type = file.fileType else { return false }
                return type == "sourcecode.c.h" || type == "sourcecode.cpp.h"
            }
            .map { $0.file(buildPhase: BuildPhase.headers.rawValue, compilerFlags: nil, attributes: []) }
    }

    private var sourceBuildFiles: [PBXBuildFile] {
        ((try? native.sourcesBuildPhase()?.files) ?? []).filter(links)
    }

    private var headerBuildFiles: [PBXBuildFile] {
        native.buildPhases
            .compactMap { $0 as? PBXHeadersBuildPhase }
            .compactMap(\.files)
            .flatMap { $0 }
            .filter(links)
    }

    private var resourceBuildFiles: [PBXBuildFile] {
        ((try? native.resourcesBuildPhase()?.files) ?? []).filter(links)
    }

    private var frameworkBuildFiles: [PBXBuildFile] {
        allFrameworkBuildFiles.filter(links)
    }

    private var allFrameworkBuildFiles: [PBXBuildFile] {
        (try? native.frameworksBuildPhase()?.files) ?? []
    }

    /// Package products the target links only on another platform.
    ///
    /// The filter is on the build file, while the product is also listed on the
    /// target itself, so the target's own list has to be read through the filter.
    private var filteredProductNames: Set<String> {
        let linked = Set(frameworkBuildFiles.compactMap { $0.product?.productName })
        let filtered = allFrameworkBuildFiles
            .filter { !links($0) }
            .compactMap { $0.product?.productName }

        return Set(filtered).subtracting(linked)
    }

    /// Whether the target links a build file at all.
    ///
    /// Xcode can restrict a linked framework or package product to some platforms
    /// — UTM links a visionOS keyboard only when building for visionOS — and the
    /// entry is invisible to every other platform, sources and all.
    private func links(_ buildFile: PBXBuildFile) -> Bool {
        let filters = (buildFile.platformFilters ?? []) + [buildFile.platformFilter].compactMap { $0 }
        guard !filters.isEmpty else { return true }
        guard let platform = platformFilterName else { return true }

        return filters.contains { filter in
            filter == platform || filter.hasPrefix("\(platform)-")
        }
    }

    /// The platform as a build file's filter names it.
    private var platformFilterName: String? {
        switch selectedConfig?.platform.resolvedSDK {
        case .iOS:
            return "ios"
        case .macOS:
            return "macos"
        case .tvOS:
            return "tvos"
        case .watchOS:
            return "watchos"
        case .driverKit:
            return "driverkit"
        case .auto, .none:
            return nil
        }
    }

    private var copyBuildFiles: [PBXBuildFile] {
        native.buildPhases
            .compactMap { $0 as? PBXCopyFilesBuildPhase }
            .compactMap(\.files)
            .flatMap { $0 }
            .filter(links)
    }

    private var synchronizedGroupFiles: [SynchronizedFile] {
        let explicit = project.explicitSynchronizedGroups(for: native).flatMap { group in
            synchronizedFiles(in: group, membershipMode: .excludeListed)
        }
        let inferred = project.inferredSynchronizedGroups(for: native).flatMap { group in
            synchronizedFiles(in: group, membershipMode: .includeListed)
        }

        return unique(explicit + inferred) { "\($0.path)|\($0.fullPath)|\($0.compilerFlags ?? "")" }
    }

    private func synchronizedFiles(
        in group: PBXFileSystemSynchronizedRootGroup,
        membershipMode: SynchronizedMembershipMode)
        -> [SynchronizedFile]
    {
        guard let relativeRoot = group.path else { return [] }
        let root = project.workspacePath + relativeRoot
        guard root.exists else { return [] }

        let membershipPaths = synchronizedMembershipPaths(group)
        let compilerFlags = synchronizedCompilerFlags(group)

        return (try? root.recursiveChildren())?
            .filter(\.isFile)
            .compactMap { file in
                let relative = file.string.delete(prefix: project.workspacePath.string + "/")
                guard let relative else { return nil }

                let pathInGroup = relative.delete(prefix: relativeRoot + "/") ?? ""
                switch membershipMode {
                case .excludeListed:
                    guard !membershipPaths.contains(pathInGroup), !membershipPaths.contains(relative) else {
                        return nil
                    }
                case .includeListed:
                    guard membershipPaths.contains(pathInGroup) || membershipPaths.contains(relative) else {
                        return nil
                    }
                }

                return SynchronizedFile(
                    path: relative,
                    fullPath: file.string,
                    compilerFlags: compilerFlags[pathInGroup] ?? compilerFlags[relative])
            } ?? []
    }

    private func synchronizedMembershipPaths(_ group: PBXFileSystemSynchronizedRootGroup) -> Set<String> {
        let buildExceptions = (group.exceptions ?? []).compactMap {
            $0 as? PBXFileSystemSynchronizedBuildFileExceptionSet
        }.filter { exception in
            exception.target?.name == name
        }

        let membershipExceptions = buildExceptions
            .compactMap(\.membershipExceptions)
            .flatMap { $0 }

        return Set(membershipExceptions)
    }

    private func synchronizedCompilerFlags(_ group: PBXFileSystemSynchronizedRootGroup) -> [String: String] {
        let buildExceptions = (group.exceptions ?? []).compactMap {
            $0 as? PBXFileSystemSynchronizedBuildFileExceptionSet
        }.filter { exception in
            exception.target?.name == name
        }

        return buildExceptions
            .compactMap(\.additionalCompilerFlagsByRelativePath)
            .reduce(into: [:]) { result, next in
                result.merge(next) { first, _ in first }
            }
    }

    private enum SynchronizedMembershipMode {
        case excludeListed
        case includeListed
    }

    private func fileModels(from buildFiles: [PBXBuildFile], buildPhase: BuildPhase) -> [Xcode.File] {
        buildFiles.flatMap { buildFile -> [Xcode.File] in
            guard let file = buildFile.file else { return [] }

            /// A localized resource is one build file referencing a variant group;
            /// what Xcode copies into the bundle are its children, one `.lproj`
            /// directory per language.
            guard let variant = file as? PBXVariantGroup else {
                return [
                    FileLoader(native: file, project: project).file(
                        buildPhase: buildPhase.rawValue,
                        compilerFlags: buildFile.compilerFlags,
                        attributes: buildFile.attributes ?? []),
                ]
            }

            let root = project.workspacePath.string
            let base = try? variant.parent?.fullPath(sourceRoot: root)

            return variant.children.compactMap { child in
                guard let path = child.path else { return nil }
                return FileLoader(
                    native: child,
                    project: project,
                    pathOverride: base.map { "\($0)/\(path)" })
                    .file(
                        buildPhase: buildPhase.rawValue,
                        compilerFlags: buildFile.compilerFlags,
                        attributes: buildFile.attributes ?? [])
            }
        }
    }
}

extension Xcode.BuildPhase {
    fileprivate init(phase: PBXBuildPhase) {
        let destination: Xcode.CopyFilesDestination?
        if let copyPhase = phase as? PBXCopyFilesBuildPhase {
            destination = .init(
                path: copyPhase.dstPath,
                subfolder: copyPhase.dstSubfolder?.rawValue,
                subfolderSpec: copyPhase.dstSubfolderSpec?.rawValue)
        } else {
            destination = nil
        }

        self.init(
            type: phase.buildPhase.rawValue,
            name: phase.name(),
            files: (phase.files ?? []).compactMap { buildFile in
                Xcode.BuildPhaseFile(
                    name: (buildFile.file as? PBXFileReference)?.name ??
                        (buildFile.file as? PBXFileReference)?.path ??
                        buildFile.product?.productName,
                    path: buildFile.file?.path,
                    fileType: (buildFile.file as? PBXFileReference)?.lastKnownFileType,
                    compilerFlags: buildFile.compilerFlags,
                    attributes: buildFile.attributes ?? [])
            },
            inputPaths: (phase as? PBXShellScriptBuildPhase)?.inputPaths ?? [],
            outputPaths: (phase as? PBXShellScriptBuildPhase)?.outputPaths ?? [],
            inputFileListPaths: phase.inputFileListPaths ?? [],
            outputFileListPaths: phase.outputFileListPaths ?? [],
            shellScript: (phase as? PBXShellScriptBuildPhase)?.shellScript,
            destination: destination)
    }
}
