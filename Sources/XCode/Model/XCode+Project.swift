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
        native.defaultConfigList?.buildSettings
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

    public init(_ projectPath: Path) async throws {
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
    }

    #warning("todo")

    // MARK: Public

    public let workspacePath: Path
    public let projectPath: Path

    public var localSPM: [String] {
        let groups = try? native.rootGroup()?.localSPM.compactMap { $0 }
        return []
    }

    // MARK: Internal

    internal var headers: [File] {
        (try? native.rootGroup()?.filterChildren(.h).map { header in
            File(native: header, project: self)
        }) ?? []
    }

    // MARK: Private

    private let project: XcodeProj
    private let native: PBXProj
    private let _spm: [RemoteSPMPackage]


    private var _targets: [Target] {
        let list = native.defaultConfigList
        return native.nativeTargets.map {
            Target(native: $0, defaultConfigList: list, project: self)
        }
    }

    internal func files(_ type: LastKnownFileType) -> [File] {
        return (try? self.native.rootGroup()?.filterChildren(type).map { header in
            File(native: header, project: self)
        }) ?? []
    }
}

extension PBXProj {
    fileprivate var defaultConfigList: ConfigList? {
        let all = Set(configurationLists.map(ConfigList.init))
        let targets = nativeTargets.compactMap { ConfigList($0.buildConfigurationList) }

        return all.subtracting(targets).first
    }
}
