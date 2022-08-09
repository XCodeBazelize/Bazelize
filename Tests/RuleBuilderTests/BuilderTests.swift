//
//  TextBuilderTests.swift
//
//
//  Created by Yume on 2022/7/29.
//

@testable import RuleBuilder
import XCTest

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
        let result = Rule("ios_framework") {
            Property("name") {
                "Test"
            }
            Property("bundle_id") {
                "com.example.test"
            }
            Property("families") {
                "1"
                "2"
            }
        }.text
        XCTAssertEqual(Self.target, result)
    }

    func testRuleBuilderArray() throws {
        let result = Rule("ios_framework") {
            Property("name") {
                "Test"
            }
            Property("bundle_id") {
                "com.example.test"
            }
            Property("families") {
                ["1", "2"]
            }
        }.text
        XCTAssertEqual(Self.target, result)
    }

    func testWithNil() throws {
        let nilStr: String? = nil

        let result = Rule("ios_framework") {
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
        let result = Rule("ios_framework") {
            Comment("Before")
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
        let result = Rule("ios_framework") {
            "data" => [
                "b": "b",
                "a": "a"
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
    
    func testWithEmptyDictionary() throws {
        let result = Rule("ios_framework") {
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
