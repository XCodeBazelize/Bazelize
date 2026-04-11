//
//  XCode+ProjectLoader.swift
//
//
//  Created by Yume on 2026/3/29.
//

import Foundation
import PathKit
import XcodeProj

final class ProjectLoader {
    private let xcodeProj: XcodeProj
    private let native: PBXProj
    private let path: Path
    fileprivate let preferConfig: String?

    init(path: Path, preferConfig: String?) throws {
        self.path = path
        self.preferConfig = preferConfig
        xcodeProj = try XcodeProj(path: path)
        native = xcodeProj.pbxproj
    }

    var rootProject: PBXProject? {
        native.rootObject
    }

    var workspacePath: Path {
        path.parent()
    }

    func model() throws -> XCode.Project {
        XCode.Project(
            name: rootProject?.name ?? path.lastComponentWithoutExtension,
            workspacePath: workspacePath.string,
            projectPath: path.string,
            preferConfig: preferConfig,
            configs: defaultConfigList?.configs ?? [:],
            packages: .init(
                remote: remotePackages,
                local: localPackages
            ),
            targets: targets.map(\.model)
        )
    }

    private lazy var allFiles: [PBXFileElement] = {
        (try? native.rootGroup()?.flatten()) ?? []
    }()

    private lazy var targets: [TargetLoader] = {
        native.nativeTargets.map {
            TargetLoader(
                native: $0,
                project: self,
                defaultConfigList: defaultConfigList
            )
        }
    }()

    private lazy var defaultConfigList: ConfigListLoader? = {
        let all = Set(native.configurationLists.map { ConfigListLoader(native: $0) })
        let targetLists = native.nativeTargets.map {
            ConfigListLoader(native: $0.buildConfigurationList)
        }

        return all.subtracting(targetLists).first
    }()

    private var remotePackages: [XCode.RemotePackage] {
        (rootProject?.remotePackages ?? []).map { package in
            .init(
                name: package.name,
                repositoryURL: package.repositoryURL,
                requirement: package.versionRequirement?.stringValue
            )
        }
    }

    private var localPackages: [XCode.LocalPackage] {
        (rootProject?.localPackages ?? []).map { package in
            .init(
                name: package.name,
                relativePath: package.relativePath
            )
        }
    }

    fileprivate func packageFiles(targetName: String) -> [FileLoader] {
        allFiles
            .compactMap { FileLoader(native: $0, project: self) }
            .filter { file in
                file.packageName == targetName
            }
    }

    func transformToLabel(_ relativePath: String?) -> String? {
        guard let path = relativePath else { return nil }

        let commentedLabel = "# \(path)"
        guard let package = path.split(separator: "/").first.map(String.init) else {
            return commentedLabel
        }
        guard let restPath = path.delete(prefix: package + "/") else {
            return commentedLabel
        }

        if targets.map(\.name).contains(package) {
            return "//\(package):\(restPath)"
        } else {
            return "//:\(package)/\(restPath)"
        }
    }
}

private struct TargetLoader {
    let native: PBXNativeTarget
    unowned let project: ProjectLoader
    let configList: ConfigListLoader
    let mergedConfig: [String: [String: XCode.JSONValue]]

    init(native: PBXNativeTarget, project: ProjectLoader, defaultConfigList: ConfigListLoader?) {
        self.native = native
        self.project = project
        configList = ConfigListLoader(native: native.buildConfigurationList)
        mergedConfig = configList.merge(defaultConfigList)
    }

    var name: String { native.name }

    var model: XCode.Target {
        let buildPhases = native.buildPhases.map(XCode.BuildPhase.init)
        let synchronizedFiles = synchronizedGroupFiles

        let sourceFiles = unique(
            fileModels(from: sourceBuildFiles, buildPhase: .sources) +
                synchronizedFiles.filter { file in
                    file.category == .source
                }.map(\.file)
        ) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }
        let headerFiles = unique(
            fileModels(from: headerBuildFiles, buildPhase: .headers) +
                packageHeaders +
                synchronizedFiles.filter { file in
                    file.category == .header
                }.map(\.file)
        ) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }
        let resourceFiles = unique(
            fileModels(from: resourceBuildFiles, buildPhase: .resources) +
                synchronizedFiles.filter { file in
                    file.category == .resource
                }.map(\.file)
        ) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }
        let frameworkFiles = fileModels(from: frameworkBuildFiles, buildPhase: .frameworks)
        let copyFiles = fileModels(from: copyBuildFiles, buildPhase: .copyFiles)

        let knownPaths = Set(
            (sourceFiles + headerFiles + resourceFiles + frameworkFiles + copyFiles)
                .compactMap(\.path)
        )

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
            configs: mergedConfig,
            metadata: metadata,
            buildPhases: buildPhases,
            files: .init(
                sources: sourceFiles,
                headers: headerFiles,
                resources: resourceFiles,
                frameworks: frameworkFiles,
                copyFiles: copyFiles,
                others: unique(otherFiles) { "\($0.path ?? "")|\($0.buildPhase ?? "")" }
            ),
            dependencies: dependencies
        )
    }

    private var metadata: XCode.TargetMetadata {
        let settings = selectedConfig ?? [:]

        return .init(
            bundleID: settings["PRODUCT_BUNDLE_IDENTIFIER"]?.stringValue,
            moduleName: settings["PRODUCT_MODULE_NAME"]?.stringValue ?? settings["PRODUCT_NAME"]?.stringValue,
            infoPlist: settings["INFOPLIST_FILE"]?.stringValue,
            deploymentTargets: deploymentTargets(from: settings),
            codeSign: .init(
                developmentTeam: settings["DEVELOPMENT_TEAM"]?.stringValue,
                codeSignStyle: settings["CODE_SIGN_STYLE"]?.stringValue,
                codeSignIdentity: settings["CODE_SIGN_IDENTITY"]?.stringValue
            )
        )
    }

    private var dependencies: XCode.Dependencies {
        let frameworkNames = frameworkBuildFiles.compactMap { buildFile -> String? in
            guard let file = buildFile.file else { return nil }
            let wrapped = FileLoader(native: file, project: project)
            guard !wrapped.isSDKFramework else { return nil }
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
                package: dependency.package?.repositoryURL
            )
        }

        let targetDependencies = native.dependencies.compactMap { dependency in
            dependency.target?.name ?? dependency.name
        }

        return .init(
            targets: Set(targetDependencies).sorted(),
            packageProducts: unique(packageProducts) { "\($0.productName)|\($0.package ?? "")" },
            frameworks: Set(frameworkNames.compactMap { $0 }).sorted(),
            sdkFrameworks: Set(sdkFrameworks.compactMap { $0 }).sorted()
        )
    }

    private var selectedConfig: [String: XCode.JSONValue]? {
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
        (native.fileSystemSynchronizedGroups ?? []).flatMap { group in
            synchronizedFiles(in: group)
        }
    }

    private func synchronizedFiles(in group: PBXFileSystemSynchronizedRootGroup) -> [SynchronizedFile] {
        guard let relativeRoot = group.path else { return [] }
        let root = project.workspacePath + relativeRoot
        guard root.exists else { return [] }

        let excluded = synchronizedExcludedPaths(group)
        let compilerFlags = synchronizedCompilerFlags(group)

        return (try? root.recursiveChildren())?
            .filter(\.isFile)
            .compactMap { file in
                let relative = file.string.delete(prefix: project.workspacePath.string + "/")
                guard let relative else { return nil }

                let pathInGroup = relative.delete(prefix: relativeRoot + "/") ?? ""
                guard !excluded.contains(pathInGroup), !excluded.contains(relative) else {
                    return nil
                }

                return SynchronizedFile(
                    path: relative,
                    fullPath: file.string,
                    compilerFlags: compilerFlags[pathInGroup] ?? compilerFlags[relative]
                )
            } ?? []
    }

    private func synchronizedExcludedPaths(_ group: PBXFileSystemSynchronizedRootGroup) -> Set<String> {
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

    private func fileModels(from buildFiles: [PBXBuildFile], buildPhase: BuildPhase) -> [XCode.File] {
        buildFiles.compactMap { buildFile in
            guard let file = buildFile.file else { return nil }
            return FileLoader(native: file, project: project).file(
                buildPhase: buildPhase.rawValue,
                compilerFlags: buildFile.compilerFlags,
                attributes: buildFile.attributes ?? []
            )
        }
    }

    private func deploymentTargets(from settings: [String: XCode.JSONValue]) -> [String: String] {
        [
            "iOS": settings["IPHONEOS_DEPLOYMENT_TARGET"]?.stringValue,
            "macOS": settings["MACOSX_DEPLOYMENT_TARGET"]?.stringValue,
            "tvOS": settings["TVOS_DEPLOYMENT_TARGET"]?.stringValue,
            "watchOS": settings["WATCHOS_DEPLOYMENT_TARGET"]?.stringValue,
            "driverKit": settings["DRIVERKIT_DEPLOYMENT_TARGET"]?.stringValue,
        ].compactMapValues { $0 }
    }
}

private struct ConfigListLoader: Hashable {
    let native: XCConfigurationList?

    var configs: [String: [String: XCode.JSONValue]] {
        (native?.buildConfigurations ?? []).map { config in
            (
                config.name,
                config.buildSettings.mapValues(XCode.JSONValue.normalize)
            )
        }.toDictionary()
    }

    func merge(_ defaultConfig: ConfigListLoader?) -> [String: [String: XCode.JSONValue]] {
        guard let defaultConfig else {
            return configs
        }

        let defaults = defaultConfig.configs
        return configs.map { name, current in
            let merged = current.merging(defaults[name] ?? [:]) { first, _ in
                first
            }
            return (
                name,
                merged
            )
        }.toDictionary()
    }

    static func == (lhs: ConfigListLoader, rhs: ConfigListLoader) -> Bool {
        lhs.native?.uuid == rhs.native?.uuid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(native?.uuid)
    }
}

private struct FileLoader {
    let native: PBXFileElement
    unowned let project: ProjectLoader

    var name: String? {
        native.name ?? native.path
    }

    var label: String? {
        project.transformToLabel(relativePath)
    }

    var packageName: String? {
        relativePath?.split(separator: "/").first.map(String.init)
    }

    var relativePath: String? {
        let root = project.workspacePath.string
        guard let fullPath else { return nil }
        guard fullPath.hasPrefix(root + "/") else { return nil }
        return fullPath.delete(prefix: root + "/")
    }

    var fullPath: String? {
        try? native.fullPath(sourceRoot: project.workspacePath.string)
    }

    var fileType: String? {
        ref?.lastKnownFileType ?? ref?.explicitFileType
    }

    var sourceTree: String {
        native.sourceTree?.description ?? ""
    }

    var frameworkName: String? {
        name?.replacingOccurrences(of: ".framework", with: "")
            .replacingOccurrences(of: ".xcframework", with: "")
    }

    var isSDKFramework: Bool {
        sourceTree == PBXSourceTree.sdkRoot.description ||
            sourceTree == PBXSourceTree.developerDir.description
    }

    private var ref: PBXFileReference? {
        native as? PBXFileReference
    }

    func file(buildPhase: String?, compilerFlags: String?, attributes: [String]) -> XCode.File {
        .init(
            name: name,
            path: relativePath ?? native.path,
            fullPath: fullPath,
            label: label,
            fileType: fileType,
            sourceTree: sourceTree,
            buildPhase: buildPhase,
            compilerFlags: compilerFlags,
            attributes: attributes
        )
    }
}

private struct SynchronizedFile {
    enum Category {
        case source
        case header
        case resource
        case other
    }

    let path: String
    let fullPath: String
    let compilerFlags: String?

    var name: String {
        Path(path).lastComponent
    }

    var fileType: String? {
        switch Path(path).extension?.lowercased() {
        case "swift": return "sourcecode.swift"
        case "m": return "sourcecode.c.objc"
        case "mm": return "sourcecode.cpp.objcpp"
        case "c": return "sourcecode.c.c"
        case "cc", "cp", "cpp", "cxx": return "sourcecode.cpp.cpp"
        case "h": return "sourcecode.c.h"
        case "hh", "hpp", "hxx": return "sourcecode.cpp.h"
        case "metal": return "sourcecode.metal"
        case "xib": return "file.xib"
        case "storyboard": return "file.storyboard"
        case "xcassets": return "folder.assetcatalog"
        case "strings": return "text.plist.strings"
        case "stringsdict": return "text.plist.stringsdict"
        case "plist": return "text.plist.xml"
        case "xcframework": return "wrapper.xcframework"
        case "framework": return "wrapper.framework"
        default: return nil
        }
    }

    var category: Category {
        switch fileType {
        case "sourcecode.swift",
             "sourcecode.c.objc",
             "sourcecode.cpp.objcpp",
             "sourcecode.c.c",
             "sourcecode.cpp.cpp",
             "sourcecode.metal":
            return .source
        case "sourcecode.c.h",
             "sourcecode.cpp.h":
            return .header
        case "file.xib",
             "file.storyboard",
             "folder.assetcatalog",
             "text.plist.strings",
             "text.plist.stringsdict",
             "text.plist.xml":
            return .resource
        default:
            return .other
        }
    }

    var file: XCode.File {
        .init(
            name: name,
            path: path,
            fullPath: fullPath,
            label: nil,
            fileType: fileType,
            sourceTree: "<group>",
            buildPhase: buildPhase,
            compilerFlags: compilerFlags,
            attributes: []
        )
    }

    private var buildPhase: String? {
        switch category {
        case .source: return BuildPhase.sources.rawValue
        case .header: return BuildPhase.headers.rawValue
        case .resource: return BuildPhase.resources.rawValue
        case .other: return nil
        }
    }
}

private extension XCode.BuildPhase {
    init(phase: PBXBuildPhase) {
        let destination: XCode.CopyFilesDestination?
        if let copyPhase = phase as? PBXCopyFilesBuildPhase {
            destination = .init(
                path: copyPhase.dstPath,
                subfolder: copyPhase.dstSubfolder?.rawValue,
                subfolderSpec: copyPhase.dstSubfolderSpec?.rawValue
            )
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
                    attributes: buildFile.attributes ?? []
                )
            },
            inputPaths: (phase as? PBXShellScriptBuildPhase)?.inputPaths ?? [],
            outputPaths: (phase as? PBXShellScriptBuildPhase)?.outputPaths ?? [],
            inputFileListPaths: phase.inputFileListPaths ?? [],
            outputFileListPaths: phase.outputFileListPaths ?? [],
            shellScript: (phase as? PBXShellScriptBuildPhase)?.shellScript,
            destination: destination
        )
    }
}

private extension XCRemoteSwiftPackageReference.VersionRequirement {
    var stringValue: String {
        switch self {
        case .upToNextMajorVersion(let version):
            return "upToNextMajorVersion(\(version))"
        case .upToNextMinorVersion(let version):
            return "upToNextMinorVersion(\(version))"
        case .range(let from, let to):
            return "range(\(from)...\(to))"
        case .exact(let version):
            return "exact(\(version))"
        case .branch(let branch):
            return "branch(\(branch))"
        case .revision(let revision):
            return "revision(\(revision))"
        }
    }
}

private extension XCode.JSONValue {
    var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }

    static func normalize(_ input: Any) -> Self {
        switch input {
        case let value as Self:
            return value
        case let value as String:
            return .string(value)
        case let value as Bool:
            return .bool(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                return .bool(value.boolValue)
            }
            if floor(value.doubleValue) == value.doubleValue {
                return .int(value.intValue)
            }
            return .double(value.doubleValue)
        case let value as [String: Any]:
            return .object(value.mapValues(Self.normalize))
        case let value as [Any]:
            return .array(value.map(Self.normalize))
        default:
            return .string(String(describing: input))
        }
    }
}

private extension PBXFileElement {
    func flatten() throws -> [PBXFileElement] {
        if let group = self as? PBXGroup {
            return group.children.flatMap { (try? $0.flatten()) ?? [] }
        }

        if let ref = self as? PBXFileReference {
            return [ref]
        }

        return []
    }
}

private extension Sequence {
    func toDictionary<K: Hashable, V>() -> [K: V] where Element == (K, V) {
        Dictionary(uniqueKeysWithValues: self)
    }
}

private func unique<T>(_ values: [T], key: (T) -> String) -> [T] {
    var result: [T] = []
    var seen = Set<String>()

    for value in values {
        let id = key(value)
        if seen.insert(id).inserted {
            result.append(value)
        }
    }

    return result
}

private extension String {
    func delete(prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}
