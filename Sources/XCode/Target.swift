//
//  Target.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj

public protocol Target {
    var name: String { get }
    var srcs: String { get }
    var resources: String { get }
    var buildSettings: BuildSettings { get }
}

extension PBXNativeTarget: Target {
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

    public var buildSettings: BuildSettings {
        .init(self)
    }
}

public extension PBXNativeTarget {
    func dump() {
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
        productType: \(productType!)
        """)

        if !packageProductDependencies.isEmpty {
            print("PackageProductDependencies:")
            for dep in packageProductDependencies {
                print("""
                - name: \(dep.productName)
                    url: \(dep.package?.repositoryURL ?? "")
                    version: \(dep.package?.versionRequirement.debugDescription ?? "")
                """)
            }
        }

        if !dependencies.isEmpty {
            print("Dependencies:")
            for dep in dependencies {
                print("""
                - name: \(dep.target?.name ?? "")
                """)
            }
        }

        if let files = try? frameworksBuildPhase()?.files, !files.isEmpty {
            print("Frameworks:")
            for file in files {
                print("""
                - product: \(file.product?.productName ?? "")
                  packageName: \(file.product?.package?.name ?? "")
                  path: \(file.file?.relativePath ?? "")
                """)
            }
        }

        if !spm_deps.isEmpty {
            print("SPM Deps:")
            for dep in spm_deps {
                print(dep)
            }
        }
    }
}
