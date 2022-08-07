//
//  Target.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj
import PluginInterface
import AnyCodable

extension Target: XCodeTarget {}
extension Target: Encodable {
    enum Keys: String, CodingKey {
        case name
        case config
        case srcs
        case resources
        case importFrameworks
        case frameworks
        case frameworks_library
        case sdkFrameworks
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(name, forKey: .name)
        try container.encode(AnyCodable(originConfig), forKey: .config)
        try container.encode(srcs, forKey: .srcs)
        try container.encode(resources, forKey: .resources)
        try container.encode(importFrameworks, forKey: .importFrameworks)
        try container.encode(frameworks, forKey: .frameworks)
        try container.encode(frameworks_library, forKey: .frameworks_library)
        try container.encode(sdkFrameworks, forKey: .sdkFrameworks)
    }
}

public final class Target {
    public let native: PBXNativeTarget
    
    unowned let project: Project
    let originConfig: [String: XCodeBuildSetting]
    public let config: [String: XCodeBuildSetting]
    public var configs: [String] {
        return config.keys.sorted { lhs, rhs in
            return lhs < rhs
        }
    }
    
    init(native: PBXNativeTarget, defaultConfigList: ConfigList?, project: Project) {
        self.native = native
        let configList: ConfigList = .init(native.buildConfigurationList)
        let defaultConfigList = defaultConfigList
        self.originConfig = configList.buildSettings
        self.config = configList.merge(defaultConfigList)
        self.project = project
    }
    
    public var name: String { native.name }
    
    public subscript(config: String) -> XCodeBuildSetting? {
        self.config[config]
    }
}

extension Target {
    private func files(_ files: [PBXBuildFile]?) -> [File] {
        return files?.compactMap { build in
            guard let file = build.file else {return nil}
            return File(native: file, project: project)
        } ?? []
    }
    
    public var srcFiles: [File] {
        return files(try? native.sourcesBuildPhase()?.files)
    }
    
    public var resourceFiles: [File] {
        return files(try? native.resourcesBuildPhase()?.files)
    }
}

extension Target {
    public var srcs: [String] {
        return srcFiles.labels
    }
    
    func srcs(_ type: LastKnownFileType) -> [String] {
        return srcFiles.filter { file in
            file.isType(type)
        }.labels
    }
    
    /// `.h` & `.pch`
    public var headers: [String] {
        return self.project
            .headers
            .labels
            .filter { label in
                label.hasPrefix("""
                "//\(name):
                """)
            }
    }

    public var resources: [String] {
        return resourceFiles.labels
    }
    
    func resources(_ type: LastKnownFileType) -> [String] {
        return resourceFiles.filter { file in
            file.isType(type)
        }.labels
    }
}

extension Target {
    /// use for `frameworks`
    public var importFrameworks: [String] {
        #warning("todo import framework/xcframework/static...")
        return []
    }
    
    /// use for `frameworks`
    public var frameworks: [String] {
        return self.native
            .dependencies
            .compactMap(\.target?.name)
            .map { framework in
                return """
                "//\(framework):\(framework)",
                """
            }
    }
    
    /// use for `xxx_library.deps`
    ///
    public var frameworks_library: [String] {
        return self.native
            .dependencies
            .compactMap(\.target?.name)
            .map { framework in
                return """
                "//\(framework):\(framework)_library",
                """
            }
    }
    
    /// use for `sdk_frameworks`
    public var sdkFrameworks: [String] {
        let builds = (try? native.frameworksBuildPhase()?.files) ?? []
        
        return builds.filter { build in
            return
                build.file?.sourceTree == .sdkRoot ||
                (build.file?.path?.hasPrefix("System/") ?? false)
        }.compactMap { build -> String? in
            return build.file?.name?.replacingOccurrences(of: ".framework", with: "")
        }.map { framework in
            return """
            "\(framework)",
            """
        }
    }
}

extension String {
    /// .swift
    /// .m
    /// .mm
    func hasExtension(_ type: String) -> Bool {
        self.hasSuffix("""
        "\(type)",
        """)
    }
}
