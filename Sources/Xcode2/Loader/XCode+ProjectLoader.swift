//
//  XCode+ProjectLoader.swift
//
//
//  Created by Yume on 2026/3/29.
//

import Foundation
import PathKit
import XcodeProj

// MARK: - ProjectLoader

final class ProjectLoader {
    private let xcodeProj: XcodeProj
    private let native: PBXProj
    private let path: Path
    let preferConfig: String?

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
                local: localPackages),
            targets: targets.map(\.model))
    }

    private lazy var allFiles: [PBXFileElement] = (try? native.rootGroup()?.flatten()) ?? []

    private lazy var targets: [TargetLoader] = native.nativeTargets.map {
        TargetLoader(
            native: $0,
            project: self,
            defaultConfigList: defaultConfigList)
    }

    private lazy var defaultConfigList: ConfigListLoader? = {
        let all = Set(native.configurationLists.map { ConfigListLoader(native: $0) })
        let targetLists = native.nativeTargets.map {
            ConfigListLoader(native: $0.buildConfigurationList)
        }

        return all.subtracting(targetLists).first
    }()
}

// MARK: - SwiftPM
extension ProjectLoader {
    private var remotePackages: [XCode.RemotePackage] {
        (rootProject?.remotePackages ?? []).map { package in
            .init(
                name: package.name,
                repositoryURL: package.repositoryURL,
                version: package.versionRequirement?.requirementValue)
        }
    }

    private var localPackages: [XCode.LocalPackage] {
        let explicit = (rootProject?.localPackages ?? []).map { package in
            XCode.LocalPackage(
                name: package.name,
                relativePath: package.relativePath)
        }
        return Self.mergeLocalPackages(
            explicit: explicit,
            discovered: discoveredLocalPackages)
    }

    private var discoveredLocalPackages: [XCode.LocalPackage] {
        allFiles
            .compactMap { FileLoader(native: $0, project: self) }
            .compactMap { file in
                guard let relativePath = file.relativePath else { return nil }
                guard let fullPath = file.fullPath else { return nil }

                let packageRoot = Path(fullPath)
                guard packageRoot.isDirectory else { return nil }
                guard (packageRoot + "Package.swift").exists else { return nil }

                return XCode.LocalPackage(
                    name: file.name ?? packageRoot.lastComponent,
                    relativePath: relativePath)
            }
    }

    func packageFiles(targetName: String) -> [FileLoader] {
        allFiles
            .compactMap { FileLoader(native: $0, project: self) }
            .filter { file in
                file.packageName == targetName
            }
    }

    func packageName(for file: PBXFileElement) -> String? {
        for target in native.nativeTargets {
            if targetOwnsFile(target: target, file: file) {
                return target.name
            }
        }

        return nil
    }

    var localPackagePathByProduct: [String: String] {
        var result: [String: String] = [:]

        for package in localPackages {
            let packageRoot = workspacePath + package.relativePath
            let manifest = packageRoot + "Package.swift"
            guard let content = try? String(contentsOfFile: manifest.string) else { continue }

            for product in content.swiftPackageProductNames {
                result[product] = package.relativePath
            }
        }

        return result
    }

    enum LabelKind {
        case source(packageName: String?)
        case prebuilt

        var packageName: String {
            switch self {
            case .source(let packageName):
                return packageName ?? ""
            case .prebuilt:
                return "Prebuilt"
            }
        }
    }

    func transformToLabel(
        _ relativePath: String?,
        _ kind: LabelKind)
        -> String?
    {
        guard let path = relativePath else { return nil }

        return "//\(kind.packageName):\(path)"
    }

    static func mergeLocalPackages(
        explicit: [XCode.LocalPackage],
        discovered: [XCode.LocalPackage])
        -> [XCode.LocalPackage]
    {
        var result: [XCode.LocalPackage] = []
        var seen = Set<String>()

        for package in explicit + discovered {
            if seen.insert(package.relativePath).inserted {
                result.append(package)
            }
        }

        return result
    }
}

extension ProjectLoader {
    private func targetOwnsFile(target: PBXNativeTarget, file: PBXFileElement) -> Bool {
        if
            target.buildPhases.contains(where: { phase in
                phase.files?.contains(where: { $0.file === file }) == true
            })
        {
            return true
        }

        guard let filePath = try? file.fullPath(sourceRoot: workspacePath.string) else {
            return false
        }

        return (target.fileSystemSynchronizedGroups ?? []).contains(where: { group in
            guard let root = try? group.fullPath(sourceRoot: workspacePath.string) else {
                return false
            }
            return filePath == root || filePath.hasPrefix(root + "/")
        })
    }
}

extension XCRemoteSwiftPackageReference.VersionRequirement {
    fileprivate var requirementValue: XCode.RemotePackage.Requirement {
        switch self {
        case .upToNextMajorVersion(let version):
            return .upToNextMajorVersion(version)
        case .upToNextMinorVersion(let version):
            return .upToNextMinorVersion(version)
        case .range(let from, let to):
            return .range(from: from, to: to)
        case .exact(let version):
            return .exact(version)
        case .branch(let branch):
            return .branch(branch)
        case .revision(let revision):
            return .revision(revision)
        }
    }
}

extension String {
    fileprivate var swiftPackageProductNames: [String] {
        let pattern = #"\.library\s*\(\s*name:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let capture = Range(match.range(at: 1), in: self) else { return nil }
            return String(self[capture])
        }
    }
}
