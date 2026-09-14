import Foundation
import PathKit
import XcodeProj

// MARK: - TargetLoader

struct TargetLoader {
    let native: PBXNativeTarget
    unowned let project: ProjectLoader
    let preferConfig: String?
    let configList: ConfigListLoader
    let mergedConfig: [String: XCode.BuildSettings]

    init(native: PBXNativeTarget, project: ProjectLoader, defaultConfigList: ConfigListLoader?) {
        self.native = native
        self.project = project
        preferConfig = project.preferConfig
        configList = ConfigListLoader(native: native.buildConfigurationList, sourceRoot: project.workspacePath)
        mergedConfig = configList.merge(defaultConfigList).mapValues { settings in
            settings.with(overrides: [
                "TARGET_NAME": native.name,
            ])
        }
    }

    var name: String { native.name }

    var model: XCode.Target {
        let buildPhases = native.buildPhases.map(XCode.BuildPhase.init)
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

        return XCode.Target(
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

    private var metadata: XCode.TargetMetadata {
        let settings = selectedConfig ?? .init(name: "", setting: [:])

        return .init(
            bundleID: settings.metadata.bundleID,
            moduleName: settings.metadata.moduleName ?? settings.metadata.productName,
            infoPlist: settings.plist.infoPlist,
            deploymentTargets: settings.platform.deploymentTargets,
            codeSign: .init(
                developmentTeam: settings.metadata.developmentTeam,
                codeSignStyle: settings.metadata.codeSignStyle,
                codeSignIdentity: settings.metadata.codeSignIdentity))
    }

    private var dependencies: XCode.Dependencies {
        let targetDependencies = native.dependencies.compactMap { dependency in
            dependency.target?.name ?? dependency.name
        }
        let targetDependencyIdentities = Set(targetDependencies)

        let frameworks = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard !wrapped.isSDKFramework else { return nil }

            if let identity = wrapped.frameworkIdentity, targetDependencyIdentities.contains(identity) {
                return nil
            }

            if
                let label = wrapped.label(buildPhase: BuildPhase.frameworks.rawValue),
                label.hasPrefix("//Prebuilt:")
            {
                return label
            }

            return wrapped.name
        }

        let sdkFrameworks = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard wrapped.isSDKFramework else { return nil }
            return wrapped.frameworkName
        }

        let packageProducts = (native.packageProductDependencies ?? []).map { dependency in
            XCode.PackageProductDependency(
                productName: dependency.productName,
                package: dependency.package?.repositoryURL,
                packagePath: project.localPackagePathByProduct[dependency.productName])
        }

        return .init(
            targets: Set(targetDependencies).sorted(),
            packageProducts: unique(packageProducts) { "\($0.productName)|\($0.package ?? "")" },
            frameworks: Set(frameworks.compactMap { $0 }).sorted(),
            sdkFrameworks: Set(sdkFrameworks.compactMap { $0 }).sorted())
    }

    private var selectedConfig: XCode.BuildSettings? {
        if let prefer = project.preferConfig, let hit = mergedConfig[prefer] {
            return hit
        }
        return mergedConfig
            .sorted { $0.key < $1.key }
            .map(\.value)
            .first
    }

    private var packageHeaders: [XCode.File] {
        project.packageFiles(targetName: name)
            .filter { file in
                guard let type = file.fileType else { return false }
                return type == "sourcecode.c.h" || type == "sourcecode.cpp.h"
            }
            .map { $0.file(buildPhase: BuildPhase.headers.rawValue, compilerFlags: nil, attributes: []) }
    }

    private var sourceBuildFiles: [PBXBuildFile] {
        (try? native.sourcesBuildPhase()?.files) ?? []
    }

    private var headerBuildFiles: [PBXBuildFile] {
        native.buildPhases
            .compactMap { $0 as? PBXHeadersBuildPhase }
            .compactMap(\.files)
            .flatMap { $0 }
    }

    private var resourceBuildFiles: [PBXBuildFile] {
        (try? native.resourcesBuildPhase()?.files) ?? []
    }

    private var frameworkBuildFiles: [PBXBuildFile] {
        (try? native.frameworksBuildPhase()?.files) ?? []
    }

    private var copyBuildFiles: [PBXBuildFile] {
        native.buildPhases
            .compactMap { $0 as? PBXCopyFilesBuildPhase }
            .compactMap(\.files)
            .flatMap { $0 }
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

    private func fileModels(from buildFiles: [PBXBuildFile], buildPhase: BuildPhase) -> [XCode.File] {
        buildFiles.compactMap { buildFile in
            guard let file = buildFile.file else { return nil }
            return FileLoader(native: file, project: project).file(
                buildPhase: buildPhase.rawValue,
                compilerFlags: buildFile.compilerFlags,
                attributes: buildFile.attributes ?? [])
        }
    }
}

extension XCode.BuildPhase {
    fileprivate init(phase: PBXBuildPhase) {
        let destination: XCode.CopyFilesDestination?
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
                XCode.BuildPhaseFile(
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
