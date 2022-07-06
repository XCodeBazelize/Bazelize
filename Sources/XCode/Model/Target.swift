//
//  Target.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj

@dynamicMemberLookup
public struct Target {
    public let native: PBXNativeTarget
    let defaultConfigList: ConfigList?
    /// Release / Debug / More...
    private var config: String = "Release"
    
    init(native: PBXNativeTarget, defaultConfigList: ConfigList?) {
        self.native = native
        self.defaultConfigList = defaultConfigList
    }
    
    public var name: String { native.name }
    public var srcs: String { native.srcs }
    public var resources: String { native.resources }
    public var configList: ConfigList { .init(native.buildConfigurationList) }
    
    mutating
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
}

extension PBXNativeTarget {
    public var srcFiles: [File] {
        guard let sourceBuildPhase = try? sourcesBuildPhase() else {
            return []
        }

        let files = sourceBuildPhase.files ?? []
        return files.compactMap(\.file)
    }

    public var srcs: String {
        return srcFiles.paths
    }

    public var resourceFiles: [File] {
        guard let phase = try? resourcesBuildPhase() else {
            return []
        }
        let files = phase.files ?? []
        return files.compactMap(\.file)
    }

    public var resources: String {
        return resourceFiles.paths
    }
    
    /// use for `frameworks`
    public var importFrameworks: String {
        #warning("todo import framework/xcframework/static...")
        return ""
    }
    
    /// use for `frameworks`
    public var frameworks: String {
        return self.dependencies.compactMap(\.target?.name).joined(separator: "\n")
    }
    
    /// use for `sdk_frameworks`
    public var sdkFrameworks: String {
        let builds = (try? frameworksBuildPhase()?.files) ?? []
        
        return builds.filter { build in
            return
                build.file?.sourceTree == .sdkRoot ||
                (build.file?.path?.hasPrefix("System/") ?? false)
        }.compactMap { build -> String? in
            return build.file?.name?.replacingOccurrences(of: ".framework", with: "")
        }.joined(separator: "\n")
    }
}

public extension Target {
    mutating func dump(config: String) {
        self.setup(config: config)
        print("""
        name: \(name)
        productType: \(native.productType!)
        sdk: \(self.sdk!)
        version: \(self.version!)
        plist build setting: \((self.plistKeys?.joined(separator: "\n") ?? "").withNewLine)
        """)
        
        if let files = try? native.frameworksBuildPhase()?.files, !files.isEmpty {
            print("Frameworks:")
            for file in files {
                print("""
                - product: \(file.product?.productName ?? "")
                  packageName: \(file.product?.package?.name ?? "")
                  path: \(file.file?.relativePath ?? "")
                """)
            }
        }

        print("""
        Sources: \(srcs.withNewLine)
        Resources: \(resources.withNewLine)
        Framework: \(native.frameworks.withNewLine)
        SDK: \(native.sdkFrameworks.withNewLine)
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
