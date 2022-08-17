//
//  TextBuilderTests.swift
//
//
//  Created by Yume on 2022/7/29.
//

import XCTest
@testable import RuleBuilder

final class RuleTests: XCTestCase {
    static let target = """
    ios_framework(
        name = "Test",
        bundle_id = "com.example.test",
        families = [
            "1",
            "2",
        ],
    )
    """

    func testRuleBuilderSimple() throws {
        let result = StarlarkRule("ios_framework") {
            StarlarkProperty("name") {
                "Test"
            }
            StarlarkProperty("bundle_id") {
                "com.example.test"
            }
            StarlarkProperty("families") {
                "1"
                "2"
            }
        }.text
        XCTAssertEqual(Self.target, result)
    }

    func testRuleBuilderArray() throws {
        let result = StarlarkRule("ios_framework") {
            StarlarkProperty("name") {
                "Test"
            }
            StarlarkProperty("bundle_id") {
                "com.example.test"
            }
            StarlarkProperty("families") {
                ["1", "2"]
            }
        }.text
        XCTAssertEqual(Self.target, result)
    }

    func testWithNil() throws {
        let nilStr: String? = nil

        let result = StarlarkRule("ios_framework") {
            "name" => {
                nilStr
            }
            "families" => {
                nilStr
                "1"
                nilStr
                "2"
                nilStr
            }
        }.text

        let target = """
        ios_framework(
            name = None,
            families = [
                "1",
                "2",
            ],
        )
        """
        XCTAssertEqual(target, result)
    }

    func testWithComment() throws {
        let result = StarlarkRule("ios_framework") {
            StarlarkComment("Before")
            "name" => "Test"
            "After"
        }.text

        let target = """
        ios_framework(
            # Before
            name = "Test",
            # After
        )
        """
        XCTAssertEqual(target, result)
    }

    func testWithDictionary() throws {
        let result = StarlarkRule("ios_framework") {
            "data" => [
                "b": "b",
                "a": "a",
            ]
        }.text

        let target = """
        ios_framework(
            data = {
                "a": "a",
                "b": "b"
            },
        )
        """
        XCTAssertEqual(target, result)
    }

    func testWithBool() throws {
        let result = StarlarkRule("ios_framework") {
            "data1" => true
            "data2" => false
        }.text

        let target = """
        ios_framework(
            data1 = True,
            data2 = False,
        )
        """
        XCTAssertEqual(target, result)
    }

    func testWithNone() throws {
        let result = StarlarkRule("ios_framework") {
            "data1" => nil
            "data2" => None
        }.text

        let target = """
        ios_framework(
            data1 = None,
            data2 = None,
        )
        """
        XCTAssertEqual(target, result)
    }

    func testWithEmptyDictionary() throws {
        let result = StarlarkRule("ios_framework") {
            "data" => [:]
        }.text

        let target = """
        ios_framework(
            data = {
            },
        )
        """
        XCTAssertEqual(target, result)
    }
}
