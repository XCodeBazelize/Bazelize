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

// MARK: - RemoteSPMPackage + Encodable

extension RemoteSPMPackage: Encodable {
    // MARK: Public


    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(url, forKey: .url)
        try container.encode(version, forKey: .version)
    }

    // MARK: Internal

    enum Keys: String, CodingKey {
        case url
        case version
    }
}

// MARK: - RemoteSPMPackage

public struct RemoteSPMPackage: XCodeSPM {
    let native: XCSwiftPackageProductDependency

    public var url: String
    public var version: XCodeSPMVersion
    init?(_ native: XCSwiftPackageProductDependency) {
        guard let url = native.package?.repositoryURL else { return nil }
        guard let requirement = native.package?.versionRequirement else { return nil }

        self.native = native
        self.url = url
        version = requirement.version
    }
}

extension XCRemoteSwiftPackageReference.VersionRequirement {
    var version: XCodeSPMVersion {
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
