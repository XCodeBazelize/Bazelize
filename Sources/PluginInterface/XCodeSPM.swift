//
//  XCodeSPM.swift
//
//
//  Created by Yume on 2022/7/29.
//

import Foundation

// MARK: - XCodeLocalSPM

/// Local SPM
///
/// Input
///   path: Local1
///   lib: `.library(name: "LocalLib1", targets: ["LocalTarget1"]),`
///   target: `.target(name: "LocalTarget1")`
///
/// Output:
///   `.package(path: "Local1"),`
///
/// // path
/// A8337967297664A800E292DC /* Local1 */ = {
///     isa = PBXFileReference;
///     lastKnownFileType = wrapper;
///     path = Local1;
///     sourceTree = "<group>";
/// };
///
/// // lib
/// A8120D06297670E5004F3FD3 /* LocalLib1 */ = {
///     isa = XCSwiftPackageProductDependency;
///     productName = LocalLib1;
/// };
/// A8120D07297670E5004F3FD3 /* LocalLib1 in Frameworks */ = {
///     isa = PBXBuildFile;
///     productRef = A8120D06297670E5004F3FD3 /* LocalLib1 */;
/// };
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

/// Remote SPM
///
/// `.package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.7"),`
///
/// A87053C629755F9200EE09CC /* AnyCodable */ = {
///     isa = XCSwiftPackageProductDependency;
///     package = A87053C529755F9200EE09CC /* XCRemoteSwiftPackageReference "AnyCodable" */;
///     productName = AnyCodable;
/// };
///
/// A87053C529755F9200EE09CC /* XCRemoteSwiftPackageReference "AnyCodable" */ = {
///     isa = XCRemoteSwiftPackageReference;
///     repositoryURL = "https://github.com/Flight-School/AnyCodable";
///     requirement = {
///         kind = upToNextMajorVersion;
///         minimumVersion = 0.6.7;
///     };
/// };
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
