//
//  Project.swift
//
//
//  Created by Yume on 2022/4/21.
//

import Foundation
import XcodeProj
import PluginInterface
import PathKit
import AnyCodable

extension Project: XCodeProject {
    public var spm: [XCodeSPM] {
        _spm
    }
    
    public var targets: [XCodeTarget] {
        _targets
    }
    
    public var config: [String : XCodeBuildSetting]? {
        return native.defaultConfigList?.buildSettings
    }
}

extension Project: Encodable {
    enum Keys: String, CodingKey {
        case workspacePath
        case projectPath
        case localSPM
        case spm
        case targets
        case config
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(workspacePath.string, forKey: .workspacePath)
        try container.encode(projectPath.string, forKey: .projectPath)
        
        try container.encode(localSPM, forKey: .localSPM)
        try container.encode(_spm, forKey: .spm)
        
        try container.encode(_targets, forKey: .targets)
        try container.encode(AnyCodable(config), forKey: .config)
    }
}

public final class Project {
    public let workspacePath: Path
    public let projectPath: Path
    private let project: XcodeProj
    private let native: PBXProj
    private let _spm: [RemoteSPMPackage]
    
    public init(_ projectPath: Path) async throws {
        let path = projectPath.parent()
        self.workspacePath = path
        self.projectPath = projectPath
        self.project = try XcodeProj(path: projectPath)
        self.native = self.project.pbxproj
        self._spm = self.native.frameworksBuildPhases
            .compactMap(\.files)
            .flatMap {$0}
            .compactMap(\.product)
            .compactMap(RemoteSPMPackage.init)
    }
    
    #warning("todo")
    public var localSPM: [String] {
        let groups = try? self.native.rootGroup()?.localSPM.compactMap{$0}
        return []
    }
    
    private var _targets: [Target] {
        let list = self.native.defaultConfigList
        return native.nativeTargets.map {
            Target(native: $0, defaultConfigList: list, project: self)
        }
    }
    
    internal var headers: [File] {
        return (try? self.native.rootGroup()?.filterChildren(.h).map { header in
            File(native: header, project: self)
        }) ?? []
    }
}

extension PBXProj {
    fileprivate var defaultConfigList: ConfigList? {
        let all = Set(self.configurationLists.map(ConfigList.init))
        let targets = nativeTargets.compactMap { ConfigList($0.buildConfigurationList) }
        
        return all.subtracting(targets).first
    }
}
