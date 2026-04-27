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
        return XCode.Project(
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
        print("local")
        return (rootProject?.localPackages ?? []).map { package in
            .init(
                name: package.name,
                relativePath: package.relativePath
            )
        }
    }

    func packageFiles(targetName: String) -> [FileLoader] {
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
