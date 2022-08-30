//
//  PropertyTests.swift
//
//
//  Created by Yume on 2022/8/3.
//

import XCTest
@testable import RuleBuilder



// MARK: - PropertyTests

final class PropertyTests: XCTestCase { }

private let label = """
name = "Target",
"""

private let labelList = """
name = [
    "Target",
],
"""

// MARK: - Single Label
extension PropertyTests {
    func testLabelList1() {
        let property = StarlarkProperty("name") {
            "Target"
        }
        XCTAssertEqual(labelList, property.text)
    }

    func testLabelList2() {
        let property = "name".property {
            "Target"
        }
        XCTAssertEqual(labelList, property.text)
    }

    func testLabelList3() {
        let property = "name" => {
            "Target"
        }
        XCTAssertEqual(labelList, property.text)
    }

    func testLabel() {
        let property = "name" => "Target"

        XCTAssertEqual(label, property.text)
    }
}

private let list = """
families = [
    "1",
    "2",
],
"""
// MARK: - Label List
extension PropertyTests {
    func testList1() {
        let property = StarlarkProperty("families") {
            "1"
            "2"
        }
        XCTAssertEqual(list, property.text)
    }

    func testList2() {
        let property = "families".property {
            "1"
            "2"
        }
        XCTAssertEqual(list, property.text)
    }

    func testList3() {
        let property = "families" => {
            "1"
            "2"
        }

        XCTAssertEqual(list, property.text)
    }
}

// MARK: - Comment
extension PropertyTests {
    func testCommentSingle1() {
        let property = "families" => {
            Starlark.comment("test")
        }
        let result = """
        families = [
            # test
        ],
        """
        XCTAssertEqual(result, property.text)
    }

    func testCommentSingle2() {
        let property = "families" => Starlark.comment("test")
        let result = """
        # test
        # families = None,
        """
        XCTAssertEqual(result, property.text)
    }
}

// MARK: - Nil Label
extension PropertyTests {
    func testNilSingle() {
        let nilString: String? = nil
        let property = "families" => {
            nilString
        }
        let result = """
        # families = None,
        """
        XCTAssertEqual(result, property.text)
    }

    func testNilMulti() {
        let nilString: String? = nil
        let property = "families" => {
            Starlark.comment("test")
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

