//
//  SPMTests.swift
//
//
//  Created by Yume on 2022/4/25.
//

@testable import Cocoapod
import Foundation
import XCTest

final class SPMTests: XCTestCase {
    private static let sourceFile: URL = .init(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .appendingPathComponent("Resource")

    private static func resource(_ file: String) -> String {
        return sourceFile.appendingPathComponent(file).path
    }
    
    private static func strings(_ file: String) throws -> String {
        return try String(contentsOfFile: resource(file), encoding: .utf8)
    }
    
    #warning("todo default spec is sub spec")
    /// Total 9 pod
    ///
    /// - AFNetworking (4.0.1):
    /// x dep's dep
    /// - Alamofire (5.6.1)
    /// - DataCompression (3.6.0)
    ///
    /// - Moya/Combine (15.0.0):
    /// ? Default Subspec
    /// - Moya/Core (15.0.0):
    /// - Moya/RxSwift (15.0.0):
    ///
    /// - Peek (5.3.0)
    /// x dep's dep
    /// - RxSwift (6.5.0)
    /// - SVProgressHUD (2.2.5)
    /// - TLPhotoPicker (2.1.6)
    /// - XLPagerTabStrip (9.0.0)
    func testParsePodfileLock() async throws {
        let code = try Self.strings("Podfile.lock")
        let lock = try PodfileLock.parse(code)
        let repos = try await lock.repos
        XCTAssertEqual(repos.count, 9)
        
        XCTAssertEqual(repos[0].name, "AFNetworking")
        XCTAssertEqual(repos[1].name, "Alamofire")
        XCTAssertEqual(repos[2].name, "DataCompression")
        XCTAssertEqual(repos[3].name, "Moya")
        XCTAssertEqual(repos[4].name, "Peek")
        XCTAssertEqual(repos[5].name, "RxSwift")
        XCTAssertEqual(repos[6].name, "SVProgressHUD")
        XCTAssertEqual(repos[7].name, "TLPhotoPicker")
        XCTAssertEqual(repos[8].name, "XLPagerTabStrip")
        
        XCTAssertEqual(repos[0].url, "https://github.com/AFNetworking/AFNetworking/archive/4.0.1.zip")
        XCTAssertEqual(repos[1].url, "https://github.com/Alamofire/Alamofire/archive/5.6.1.zip")
        XCTAssertEqual(repos[2].url, "https://github.com/mw99/DataCompression/archive/2c0d48be59acd5bdf1a5352d969d6f24bd7212c9.zip")
        XCTAssertEqual(repos[3].url, "https://github.com/Moya/Moya/archive/15.0.0.zip")
        XCTAssertEqual(repos[4].url, "https://github.com/shaps80/Peek/archive/5.3.0.zip")
        XCTAssertEqual(repos[5].url, "https://github.com/ReactiveX/RxSwift/archive/6.5.0.zip")
        XCTAssertEqual(repos[6].url, "https://github.com/SVProgressHUD/SVProgressHUD/archive/2.2.5.zip")
        XCTAssertEqual(repos[7].url, "https://github.com/tilltue/TLPhotoPicker/archive/0d0cbbd2d20ed5fd36e5f4052209f5e2d9aaa8b7.zip")
        XCTAssertEqual(repos[8].url, "https://github.com/xmartlabs/XLPagerTabStrip/archive/master.zip")
    }
    
    func testParsePodfile() async throws {
        let code = try Self.strings("Podfile")
        let podfile = try Podfile.parse(code)
        
        let result = podfile["ABCDEF"]
        let deps = """
        "//Vendor/AFNetworking:AFNetworking",
        "//Vendor/DataCompression:DataCompression",
        "//Vendor/Moya:Combine",
        "//Vendor/Moya:RxSwift",
        "//Vendor/Peek:Peek",
        "//Vendor/SVProgressHUD:SVProgressHUD",
        "//Vendor/TLPhotoPicker:TLPhotoPicker",
        "//Vendor/XLPagerTabStrip:XLPagerTabStrip",
        """
        
        XCTAssertEqual(result, deps)
    }
}
