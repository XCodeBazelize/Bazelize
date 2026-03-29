//
//  XCodeSPM.swift
//
//
//  Created by Yume on 2022/7/29.
//

import Foundation

// MARK: - XCodeLocalSPM

public struct XCodeLocalSPM: Encodable {
    public let path: String
    public let products: [String: [String]]
    public let targets: [String]

    public init(path: String, products: [String: [String]], targets: [String]) {
        self.path = path
        self.products = products
        self.targets = targets
    }

    public var package: String {
        """
        .package(path: "\(path)"),
        """
    }
}

// MARK: - XCodeRemoteSPM

public struct XCodeRemoteSPM: Encodable {
    public let url: String
    public let version: Version

    public init(url: String, version: XCodeRemoteSPM.Version) {
        self.url = url
        self.version = version
    }

    public enum Version: Encodable {
        case upToNextMajorVersion(String)
        case upToNextMinorVersion(String)
        case range(from: String, to: String)
        case exact(String)
        case branch(String)
        case revision(String)

        var version: String {
            switch self {
            case .upToNextMajorVersion(let version):
                return """
                from: "\(version)"
                """
            case .upToNextMinorVersion(let version):
                return """
                from: "\(version)"
                """
            case .range(let from, let to):
                return """
                "\(from)"..."\(to)"
                """
            case .exact(let version):
                return """
                exact: "\(version)"
                """
            case .branch(let branch):
                return """
                branch: "\(branch)"
                """
            case .revision(let revision):
                return """
                revision: \(revision)
                """
            }
        }
    }

    public var package: String {
        """
        .package(url: "\(url)", \(version.version)),
        """
    }
}
