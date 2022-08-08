//
//  Target.swift
//
//
//  Created by Yume on 2022/4/25.
//

import AnyCodable
import Foundation
import PluginInterface
import XcodeProj

// MARK: - Target + XCodeTarget

extension Target: XCodeTarget { }

// MARK: - Target + Encodable

extension Target: Encodable {
    // MARK: Public

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(name, forKey: .name)
        try container.encode(AnyCodable(originConfig), forKey: .config)
        try container.encode(headers, forKey: .headers)
        try container.encode(srcs, forKey: .srcs)
        try container.encode(resources, forKey: .resources)
        try container.encode(importFrameworks, forKey: .importFrameworks)
        try container.encode(frameworks, forKey: .frameworks)
        try container.encode(frameworks_library, forKey: .frameworks_library)
        try container.encode(sdkFrameworks, forKey: .sdkFrameworks)
    }

    // MARK: Internal

    enum Keys: String, CodingKey {
        case name
        case config
        case headers
        case srcs
        case resources
        case importFrameworks
        case frameworks
        case frameworks_library
        case sdkFrameworks
    }
}

// MARK: - Target

public final class Target {
    // MARK: Lifecycle

    init(native: PBXNativeTarget, defaultConfigList: ConfigList?, project: Project) {
        self.native = native
        let configList: ConfigList = .init(native.buildConfigurationList)
        let defaultConfigList = defaultConfigList
        originConfig = configList.buildSettings
        config = configList.merge(defaultConfigList)
        self.project = project
    }

    // MARK: Public

    public let native: PBXNativeTarget
    public let config: [String: XCodeBuildSetting]

    public var configs: [String] {
        config.keys.sorted { lhs, rhs in
            lhs < rhs
        }
    }

    public var name: String { native.name }


    public subscript(config: String) -> XCodeBuildSetting? {
        self.config[config]
    }

    // MARK: Internal

    unowned let project: Project
    let originConfig: [String: XCodeBuildSetting]
}

extension Target {
    // MARK: Public

    public var srcFiles: [File] {
        files(try? native.sourcesBuildPhase()?.files)
    }

    public var resourceFiles: [File] {
        files(try? native.resourcesBuildPhase()?.files)
    }

    // MARK: Private

    private func files(_ files: [PBXBuildFile]?) -> [File] {
        files?.compactMap { build in
            guard let file = build.file else { return nil }
            return File(native: file, project: project)
        } ?? []
    }
}

extension Target {
    /// `.h` & `.pch`
    public var headers: [String] {
        return self.project
            .files(.h)
            .labels
            .filter { label in
                label.hasPrefix("""
                "//\(name):
                """)
            }
    }
    
    public var hpps: [String] {
        return self.project
            .files(.hpp)
            .labels
            .filter { label in
                label.hasPrefix("""
                "//\(name):
                """)
            }
    }
    
    public var srcs: [String] {
        return srcFiles.labels
    }

    public var srcs_c: [String] {
        return self.srcs(.c)
    }
    
    public var srcs_objc: [String] {
        return self.srcs(.objc)
    }
    
    public var srcs_cpp: [String] {
        return self.srcs(.cpp)
    }
    
    public var srcs_objcpp: [String] {
        return self.srcs(.objcpp)
    }
    
    public var srcs_swift: [String] {
        return self.srcs(.swift)
    }
    
    public var srcs_metal: [String] {
        return self.srcs(.metal)
    }
    
    func srcs(_ type: LastKnownFileType) -> [String] {
        return srcFiles.filter { file in
            file.isType(type)
        }.labels
    }

    public var resources: [String] {
        resourceFiles.labels
    }

    // MARK: Internal

    func srcs(_ type: LastKnownFileType) -> [String] {
        srcFiles.filter { file in
            file.isType(type)
        }.labels
    }

    func resources(_ type: LastKnownFileType) -> [String] {
        resourceFiles.filter { file in
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
        native
            .dependencies
            .compactMap(\.target?.name)
            .map { framework in
                """
                "//\(framework):\(framework)",
                """
            }
    }

    /// use for `xxx_library.deps`
    ///
    public var frameworks_library: [String] {
        native
            .dependencies
            .compactMap(\.target?.name)
            .map { framework in
                """
                "//\(framework):\(framework)_library",
                """
            }
    }

    /// use for `sdk_frameworks`
    public var sdkFrameworks: [String] {
        let builds = (try? native.frameworksBuildPhase()?.files) ?? []

        return builds.filter { build in
            build.file?.sourceTree == .sdkRoot ||
                (build.file?.path?.hasPrefix("System/") ?? false)
        }.compactMap { build -> String? in
            build.file?.name?.replacingOccurrences(of: ".framework", with: "")
        }.map { framework in
            """
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
        hasSuffix("""
        "\(type)",
        """)
    }
}
