//
//  PropertyTests.swift
//
//
//  Created by Yume on 2022/8/3.
//

import XCTest
@testable import RuleBuilder

final class PropertyTests: XCTestCase {
    static let resultSingle = """
    name = "Target",
    """

    static let resultMulti = """
    families = [
        "1",
        "2",
    ],
    """


    func testSingle1() {
        let property = Property("name") {
            "Target"
        }
        XCTAssertEqual(Self.resultSingle, property.text)
    }

    func testSingle2() {
        let property = "name".property {
            "Target"
        }
        XCTAssertEqual(Self.resultSingle, property.text)
    }

    func testSingle3() {
        let property = "name" => "Target"

        XCTAssertEqual(Self.resultSingle, property.text)
    }

    func testSingle4() {
        let property = "name" => {
            "Target"
        }
        XCTAssertEqual(Self.resultSingle, property.text)
    }

    func testMulti1() {
        let property = Property("families") {
            "1"
            "2"
        }
        XCTAssertEqual(Self.resultMulti, property.text)
    }

    func testMulti2() {
        let property = "families".property {
            "1"
            "2"
        }
        XCTAssertEqual(Self.resultMulti, property.text)
    }

    func testMulti3() {
        let property = "families" => {
            "1"
            "2"
        }

        XCTAssertEqual(Self.resultMulti, property.text)
    }

    func testCommentSingle() {
        let property = "families" => {
            Comment("test")
        }
        let result = """
        families = None, # test
        """
        XCTAssertEqual(result, property.text)
    }

    func testNilSingle() {
        let nilString: String? = nil
        let property = "families" => {
            nilString
        }
        let result = """
        families = None,
        """
        XCTAssertEqual(result, property.text)
    }

    func testNilMulti() {
        let nilString: String? = nil
        let property = "families" => {
            Comment("test")
            nilString
            "1"
            nilString
            "2"
            nilString
        }
        let result = """
        families = [
            # test
            "1",
            "2",
        ],
        """
        XCTAssertEqual(result, property.text)
    }
}
