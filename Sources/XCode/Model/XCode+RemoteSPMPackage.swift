//
//  XCodeSPM.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj
import Util
import PluginInterface

extension RemoteSPMPackage: Encodable {
    enum Keys: String, CodingKey {
        case url
        case version
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(url, forKey: .url)
        try container.encode(version, forKey: .version)
    }
}

public struct RemoteSPMPackage: XCodeSPM {
    let native: XCSwiftPackageProductDependency

    public var url: String
    public var version: XCodeSPMVersion
    init?(_ native: XCSwiftPackageProductDependency) {
        guard let url = native.package?.repositoryURL else {return nil}
        guard let requirement = native.package?.versionRequirement else {return nil}
        
        self.native = native
        self.url = url
        self.version = requirement.version
    }
}

extension XCRemoteSwiftPackageReference.VersionRequirement {
    var version: XCodeSPMVersion {
        switch self {
        case let .upToNextMajorVersion(version): return .upToNextMajorVersion(version)
        case let .upToNextMinorVersion(version): return .upToNextMinorVersion(version)
        case let .range(from, to): return .range(from: from, to: to)
        case let .exact(version): return .exact(version)
        case let .branch(branch): return .branch(branch)
        case let .revision(commit): return .revision(commit)
        }
    }
}
