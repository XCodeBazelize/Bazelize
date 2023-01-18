//
//  XCodeSPM.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import PluginInterface
import Util
import XcodeProj

extension XCodeSPMPackage {
    public static func parse(_ native: XCSwiftPackageProductDependency) -> XCodeSPMPackage? {
        let package = native.package
        guard
            let url = package?.repositoryURL,
            let requirement = package?.versionRequirement else
        {
            return .local(path: "", targets: [])
        }
        return .remote(url: url, version: requirement.version)
    }
}

extension XCRemoteSwiftPackageReference.VersionRequirement {
    var version: XCodeSPMPackage.Version {
        switch self {
        case .upToNextMajorVersion(let version): return .upToNextMajorVersion(version)
        case .upToNextMinorVersion(let version): return .upToNextMinorVersion(version)
        case .range(let from, let to): return .range(from: from, to: to)
        case .exact(let version): return .exact(version)
        case .branch(let branch): return .branch(branch)
        case .revision(let commit): return .revision(commit)
        }
    }
}
