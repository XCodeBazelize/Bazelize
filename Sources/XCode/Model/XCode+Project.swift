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
    public var spm: [XCodeSPM] {
        _spm
    }

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
        try container.encode(_spm, forKey: .spm)

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
    // MARK: Lifecycle

    public init(_ projectPath: Path, _ preferConfig: String?) async throws {
        let path = projectPath.parent()
        workspacePath = path
        self.projectPath = projectPath
        project = try XcodeProj(path: projectPath)
        native = project.pbxproj
        _spm = native.frameworksBuildPhases
            .compactMap(\.files)
            .flatMap { $0 }
            .compactMap(\.product)
            .compactMap(RemoteSPMPackage.init)
        self.preferConfig = preferConfig
    }

    // MARK: Public

    public let workspacePath: Path
    public let projectPath: Path
    public let preferConfig: String?

    /// https://github.com/XCodeBazelize/Bazelize/issues/15
    public var localSPM: [String] {
        // let groups = try? native.rootGroup()?.localSPM.compactMap { $0 }
        []
    }

    public var all: [File] {
        let all = try? native.rootGroup()?.flatten().map { file in
            File(native: file, project: self)
        }

        return all ?? []
    }

    public func files(_ type: LastKnownFileType) -> [File] {
        all.filter { file in
            file.isType(type)
        }
    }

    // MARK: Private

    private let project: XcodeProj
    private let native: PBXProj
    private let _spm: [RemoteSPMPackage]


    private var _targets: [Target] {
        let list = defaultConfigList
        return native.nativeTargets.map {
            Target(native: $0, defaultConfigList: list, project: self)
        }
    }
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
