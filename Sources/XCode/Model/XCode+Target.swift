//
//  Target.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj

@dynamicMemberLookup
public final class Target {
    public let native: PBXNativeTarget
    let defaultConfigList: ConfigList?
    let projectConfig: ProjectConfig
    
    /// Release / Debug / More...
    private var config: String = "Release"
    
    
    init(native: PBXNativeTarget, defaultConfigList: ConfigList?, projectConfig: ProjectConfig) {
        self.native = native
        self.defaultConfigList = defaultConfigList
        self.projectConfig = projectConfig
    }
    
    public var name: String { native.name }
    public var configList: ConfigList { .init(native.buildConfigurationList) }
    
    public func setup(config: String) {
        self.config = config
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<BuildSetting, T>) -> T? {
        return
            configList[config]?[keyPath: keyPath] ??
            defaultConfigList?[config]?[keyPath: keyPath]
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<BuildSetting, T?>) -> T? {
        return
            configList[config]?[keyPath: keyPath] ??
            defaultConfigList?[config]?[keyPath: keyPath]
    }
    
    public var version: String? {
        switch self.sdk {
        case .iOS: return self.iOS
        case .macOS: return self.macOS
        case .tvOS: return self.tvOS
        case .watchOS: return self.watchOS
        case .DriverKit: return self.driverKit
        case .none: return nil
        }
    }
    
    #warning("todo plist gen")
    public var plistLabel: String {
        return projectConfig.toLabel(self.infoPlist) ?? "\":Info.plist\","
    }
}

extension Target {
    public var srcFiles: [File] {
        guard let sourceBuildPhase = try? native.sourcesBuildPhase() else {
            return []
        }

        let files = sourceBuildPhase.files ?? []
        return files.compactMap { build in
            guard let file = build.file else {return nil}
            return File(native: file, config: projectConfig)
        }
    }

    public var srcs: String {
        return srcFiles.labels
    }

    public var resourceFiles: [File] {
        guard let phase = try? native.resourcesBuildPhase() else {
            return []
        }
        let files = phase.files ?? []
        return files.compactMap { build in
            guard let file = build.file else {return nil}
            return File(native: file, config: projectConfig)
        }
    }

    public var resources: String {
        return resourceFiles.labels
    }
    
    /// use for `frameworks`
    public var importFrameworks: String {
        #warning("todo import framework/xcframework/static...")
        return ""
    }
    
    /// use for `frameworks`
    public var frameworks: String {
        return self.native
            .dependencies
            .compactMap(\.target?.name)
            .map { framework in
                return """
                "//\(framework):\(framework)",
                """
            }
            .joined(separator: "\n")
    }
    
    /// use for `xxx_library.deps`
    ///
    public var frameworks_library: String {
        return self.native
            .dependencies
            .compactMap(\.target?.name)
            .map { framework in
                return """
                "//\(framework):\(framework)_library",
                """
            }
            .joined(separator: "\n")
    }
    
    /// use for `sdk_frameworks`
    public var sdkFrameworks: String {
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
        .joined(separator: "\n")
    }
}

public extension Target {
    func dump(config: String) {
        self.setup(config: config)
        print("""
        name: \(name)
        productType: \(native.productType!)
        sdk: \(self.sdk!)
        version: \(self.version!)
        plist build setting: \((self.plistKeys?.joined(separator: "\n") ?? "").withNewLine)
        """)
        
//        if let files = try? native.frameworksBuildPhase()?.files, !files.isEmpty {
//            print("Frameworks:")
//            for file in files {
//                print("""
//                - product: \(file.product?.productName ?? "")
//                  packageName: \(file.product?.package?.name ?? "")
//                  path: \(file.file?.relativePath ?? "")
//                """)
//            }
//        }

        print("""
        Sources: \(srcs.withNewLine)
        Resources: \(resources.withNewLine)
        Framework: \(frameworks.withNewLine)
        SDK: \(sdkFrameworks.withNewLine)
        SPM Deps: \(native.spm_deps.withNewLine)
        """)
    }
}

fileprivate extension String {
    var withNewLine: String {
        if self.isEmpty {
            return ""
        } else {
            return "\n" + self
        }
    }
}
