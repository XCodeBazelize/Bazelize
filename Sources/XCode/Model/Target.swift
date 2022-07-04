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
}

public extension Target {
    mutating func dump(config: String) {
        self.setup(config: config)
        /// Embed Framework
        //            po target.embedFrameworksBuildPhases()[0].files![0].file?.relativePath
        //            "DEF.framework"
        //
        //                / dependencies
        //            target.dependencies
        //            DEF
        //
        //                / framework library
        //            po target.frameworksBuildPhase()?.files?.map(\.file?.relativePath)
        //                ▿ [String?]?
        //                ▿ some: 4 elements
        //                ▿ 0: String?
        //                - some: "DEF.framework"
        //                - 1: nil
        //                ▿ 2: String?
        //                - some: "System/Library/Frameworks/Accounts.framework"
        //                ▿ 3: String?
        //                - some: "Pods_ABCDEF.framework"
        print("""
        name: \(name)
        productType: \(native.productType!)
        sdk: \(self.sdk!)
        version: \(self.version!)
        """)

        print("""
        plist build setting:
        \(self.plistKeys?.joined(separator: "\n"))
        """)

        if !native.packageProductDependencies.isEmpty {
            print("PackageProductDependencies:")
            for dep in native.packageProductDependencies {
                print("""
                - name: \(dep.productName)
                  url: \(dep.package?.repositoryURL ?? "")
                  version: \(dep.package?.versionRequirement.debugDescription ?? "")
                """)
            }
        }

        if !native.dependencies.isEmpty {
            print("Dependencies:")
            for dep in native.dependencies {
                print("""
                - name: \(dep.target?.name ?? "")
                """)
            }
        }

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

        if !native.spm_deps.isEmpty {
            print("SPM Deps:")
            for dep in native.spm_deps {
                print(dep)
            }
        }
    }
}
