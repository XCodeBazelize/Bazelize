//
//  Project.swift
//
//
//  Created by Yume on 2022/4/21.
//

import AnyCodable
import Foundation
import PathKit
import PluginInterface
import XcodeProj

// MARK: - Project + XCodeProject

extension Project: XCodeProject {
    public var targets: [XCodeTarget] {
        _targets
    }

    public var config: [String : XCodeBuildSetting]? {
        defaultConfigList?.buildSettings
    }
}

// MARK: - Project + Encodable

extension Project: Encodable {
    // MARK: Public

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(workspacePath.string, forKey: .workspacePath)
        try container.encode(projectPath.string, forKey: .projectPath)

        try container.encode(localSPM, forKey: .localSPM)
//        try container.encode(_spm, forKey: .spm)

        try container.encode(_targets, forKey: .targets)
        try container.encode(AnyCodable(config), forKey: .config)
    }

    // MARK: Internal

    enum Keys: String, CodingKey {
        case workspacePath
        case projectPath
        case localSPM
        case spm
        case targets
        case config
    }
}

// MARK: - Project

public final class Project {
    private let project: XcodeProj
    private let native: PBXProj

    public let workspacePath: Path
    public let projectPath: Path
    public let preferConfig: String?

    public init(_ projectPath: Path, _ preferConfig: String?) async throws {
        let path = projectPath.parent()
        workspacePath = path
        self.projectPath = projectPath
        project = try XcodeProj(path: projectPath)
        native = project.pbxproj
        self.preferConfig = preferConfig
    }

    public var all: [File] {
        let all = try? native.rootGroup()?.flatten().map { file in
            File(native: file, project: self)
        }

        return all ?? []
    }

    public func files(_ type: LastKnownFileType) -> [File] {
        all.filter { file in
            file.lastKnownFileType == type
        }
    }

    public lazy var remoteSPM: [XCodeRemoteSPM] = native.frameworksBuildPhases
        .compactMap(\.files)
        .flatMap { $0 }
        .compactMap(\.product)
        .compactMap(XCodeRemoteSPM.parse)

    public lazy var localSPM: [XCodeLocalSPM] = (files(.wrapper) + files(.folder)).compactMap { file in
        guard let path = file.relativePath else { return nil }
        guard let fullPath = file.fullPath else { return nil }
        guard let (products, targets) = try? SPMParser.parse(path: fullPath) else { return nil }
        return XCodeLocalSPM(path: path, products: products, targets: targets)
    }

    public lazy var frameworks: [File] = native.frameworksBuildPhases
        .compactMap(\.files)
        .flatMap { $0 }
        .compactMap(\.file)
        .map { file in
            File(native: file, project: self)
        }

    private lazy var _targets: [Target] = {
        let list = defaultConfigList
        return native.nativeTargets.map {
            Target(native: $0, defaultConfigList: list, project: self)
        }
    }()
}

// extension PBXProj {
extension Project {
    private var defaultConfigList: ConfigList? {
        let all = Set(native.configurationLists.map { ConfigList(self, $0) })
        let targets = native.nativeTargets
            .compactMap { ConfigList(self, $0.buildConfigurationList) }

        return all.subtracting(targets).first
    }
}
