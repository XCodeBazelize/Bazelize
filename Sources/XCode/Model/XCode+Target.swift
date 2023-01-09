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
        let configList: ConfigList = .init(project, native.buildConfigurationList)
        let defaultConfigList = defaultConfigList
        originConfig = configList.buildSettings
        config = configList.merge(defaultConfigList)
        self.project = project
    }

    // MARK: Public

    public let native: PBXNativeTarget
    public let config: [String: XCodeBuildSetting]

    public unowned let project: Project

    public var configs: [String] {
        config.keys.sorted { lhs, rhs in
            lhs < rhs
        }
    }

    public var name: String { native.name }


    public subscript(config: String) -> XCodeBuildSetting? {
        self.config[config]
    }

    // MARK: Private

    private let originConfig: [String: XCodeBuildSetting]
}

extension Target {
    // MARK: Internal

    func isInPackage(_ label: String) -> Bool {
        label.hasPrefix("""
        //\(name):
        """)
    }

    // MARK: Private

    private func files(_ files: [PBXBuildFile]?) -> [File] {
        files?.flatMap { build -> [File] in
            guard let files = build.file?.flatten() else { return [] }
            return files.map { native -> File in
                File(native: native, project: project)
            }
        } ?? []
    }
}

/// srcs
extension Target {
    // MARK: Public

    /// `.h` & `.pch`
    public var headers: [String] {
        project
            .files(.h)
            .labels
            .filter(isInPackage)
    }

    public var hpps: [String] {
        project
            .files(.hpp)
            .labels
            .filter(isInPackage)
    }

    public var srcFiles: [File] {
        files(try? native.sourcesBuildPhase()?.files)
    }

    public var srcs: [String] {
        srcFiles.labels
    }

    public var srcs_c: [String] {
        srcs(.c)
    }

    public var srcs_objc: [String] {
        srcs(.objc)
    }

    public var srcs_cpp: [String] {
        srcs(.cpp)
    }

    public var srcs_objcpp: [String] {
        srcs(.objcpp)
    }

    public var srcs_swift: [String] {
        srcs(.swift)
    }

    public var srcs_metal: [String] {
        srcs(.metal)
    }

    // MARK: Internal

    func srcs(_ type: LastKnownFileType) -> [String] {
        srcFiles.filter { file in
            file.isType(type)
        }.labels
    }
}

extension Target {
    // MARK: Public

    public var resourceFiles: [File] {
        files(try? native.resourcesBuildPhase()?.files)
    }

    public var xibs: [String] {
        resources(.xib)
    }

    public var storyboards: [String] {
        resources(.storyboard)
    }

    public var assets: [String] {
        resources(.asset)
    }

    public var strings: [String] {
        resources(.strings)
    }

    public var stringsdict: [String] {
        resources(.stringsdict)
    }

    public var allStrings: [String] {
        strings + stringsdict
    }

    public var resources: [String] {
        resourceFiles.labels
    }

    // MARK: Internal

    func resources(_ type: LastKnownFileType) -> [String] {
        resourceFiles.filter { file in
            file.isType(type)
        }.labels
    }
}

extension Target {
    /// https://github.com/XCodeBazelize/Bazelize/issues/8
    /// use for `frameworks`
    public var importFrameworks: [String] {
        []
    }

    /// use for `frameworks`
    public var frameworks: [String] {
        native
            .dependencies
            .compactMap(\.target?.name)
            .map { framework in
                """
                //\(framework):\(framework)
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
                //\(framework):\(framework)_library
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
            \(framework)
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
        \(type)
        """)
    }
}
