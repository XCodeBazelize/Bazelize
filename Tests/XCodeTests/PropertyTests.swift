//
//  PropertyTests.swift
//
//
//  Created by Yume on 2022/8/3.
//

import Testing
import XcodeProj
@testable import XCode

// MARK: - Setting

private struct Setting: @unchecked Sendable {
    // MARK: Lifecycle

    init(_ setting: [String: Any]) {
        self.setting = setting
    }

    // MARK: Internal

    let setting: [String: Any]

    var plist: [String] { [] }

    var name: String { "" }

    var bundleID: String? { self[#function] }

    var team: String? { self[#function] }

    var swiftVersion: String? { self[#function] }

    var deviceFamily: [DeviceFamily] { [] }

    var sdk: SDK? { nil }

    var iOS: String? { self[#function] }

    var macOS: String? { self[#function] }

    var tvOS: String? { self[#function] }

    var watchOS: String? { self[#function] }

    var driverKit: String? { self[#function] }

    var generateInfoPlist: Bool { false }

    var plistKeys: [String] { [] }

    var infoPlist: String? { nil }

    var defaultPlist: [String] { [] }

    var launch: String? { self[#function] }

    var storyboard: String? { self[#function] }

    var testHost: String? { nil }
    var testTargetName: String? { nil }
    var bundleLoader: String? { nil }

    var swiftDefine: String? { nil }
    var enableModules: Bool { false }

    // MARK: Private

    private subscript<T>(key: String) -> T? {
        setting[key] as? T
    }
}

// MARK: - XCodeTests

enum XCodeTests {
    private static let release = Setting([
        "iOS": "9.0",
        "macOS": "10.15",
    ])
    private static let debug = Setting([
        "iOS": "10.0",
        "macOS": "10.15",
    ])
    private static let config: [String: Setting] = [
        "Release": release,
        "Debug": debug,
    ]
}

// MARK: Test Select
extension XCodeTests {
    @Test
    func testSelectSame() {
        let code = Self.config.select(\.macOS).starlark.text
        #expect(code == """
        "10.15"
        """)
    }

    @Test
    func testSelectVarious() {
        let code = Self.config.select(\.iOS).starlark.text
        #expect(code == """
        select({
            "//:Debug": "10.0",
            "//:Release": "9.0"
        })
        """)
    }
}

// MARK: Test Prefer
extension XCodeTests {
    @Test
    func testPreferHit() {
        let code = Self.config.prefer(config: "Release", \.iOS)
        #expect(code == "9.0")
    }

    @Test
    func testPreferNotHit() {
        let code = Self.config.prefer(config: "Release2", \.iOS)
        #expect(code == "10.0")
    }

    @Test
    func testPreferNoValue() {
        let config: [String: Setting] = [:]
        let code = config.prefer(config: "Release", \.iOS)
        #expect(code == nil)
    }
}
