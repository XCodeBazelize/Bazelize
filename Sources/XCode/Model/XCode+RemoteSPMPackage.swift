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

extension XCodeRemoteSPM {
    public static func parse(_ native: XCSwiftPackageProductDependency) -> XCodeRemoteSPM? {
        let package = native.package
        guard
            let url = package?.repositoryURL,
            let requirement = package?.versionRequirement
        else {
            return nil
        }
        return XCodeRemoteSPM(url: url, version: requirement.version)
    }
}

extension XCRemoteSwiftPackageReference.VersionRequirement {
    var version: XCodeRemoteSPM.Version {
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
