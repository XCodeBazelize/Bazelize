//
//  PropertyTests.swift
//
//
//  Created by Yume on 2022/8/3.
//

import Testing
@testable import RuleBuilder

// MARK: - PropertyTests

struct PropertyTests { }

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
    @Test
    func testLabelList1() {
        let property = Starlark.Statement.Argument.named("name", builder: {
            "Target"
        })
        #expect(property.text == labelList)
    }

    @Test
    func testLabelList2() {
        let property = "name".property {
            "Target"
        }
        #expect(property.text == labelList)
    }

    @Test
    func testLabelList3() {
        let property = "name" => {
            "Target"
        }
        #expect(property.text == labelList)
    }

    @Test
    func testLabel() {
        let property = "name" => "Target"

        #expect(property.text == label)
    }

    @Test
    func testTypedLabel() {
        let property = "name" => Starlark.Label.named("//Lib:Core")
        let result = """
        name = "//Lib:Core",
        """
        #expect(property.text == result)
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
    @Test
    func testList1() {
        let property = Starlark.Statement.Argument.named("families", builder: {
            "1"
            "2"
        })
        #expect(property.text == list)
    }

    @Test
    func testList2() {
        let property = "families".property {
            "1"
            "2"
        }
        #expect(property.text == list)
    }

    @Test
    func testList3() {
        let property = "families" => {
            "1"
            "2"
        }

        #expect(property.text == list)
    }

    @Test
    func testIntList() {
        let property = "families" => [1, 2]
        let result = """
        families = [
            1,
            2,
        ],
        """
        #expect(property.text == result)
    }
}

extension PropertyTests {
    @Test
    func testInt() {
        let property = "stamp" => 1
        let result = """
        stamp = 1,
        """
        #expect(property.text == result)
    }

    @Test
    func testDictionaryValue() {
        let property = "env" => Starlark.Value.dictionary(["FOO": .string("BAR")])
        let result = """
        env = {
            "FOO": "BAR"
        },
        """
        #expect(property.text == result)
    }

    @Test
    func testSelectValue() {
        let property = "value" => Starlark.Select<String>.various([
            .config("Debug"): "debug",
            .default: "release",
        ])
        let result = """
        value = select({
            "//:Debug": "debug",
            "//conditions:default": "release"
        }),
        """
        #expect(property.text == result)
    }
}

// MARK: - Comment
// extension PropertyTests {
//    func testCommentSingle1() {
//        let property = "families" => {
//            Starlark.Statement.comment("test")
//        }
//        let result = """
//        families = [
//            # test
//        ],
//        """
//        XCTAssertEqual(result, property.text)
//    }
//
//    func testCommentSingle2() {
//        let property = "families" => Starlark.Statement.Argument.Comment("test")
//        let result = """
//        # test
//        # families = None,
//        """
//        XCTAssertEqual(result, property.text)
//    }
// }

// MARK: - Nil Label
extension PropertyTests {
    @Test
    func testNilSingle() {
        let nilString: String? = nil
        let property = "families" => {
            nilString
        }
        let result = """
        # families = None,
        """
        #expect(property.text == result)
    }

    @Test
    func testNilMulti() {
        let nilString: String? = nil
        let property = "families" => {
//            Starlark.Statement.comment("test")

            nilString
            "1"
            nilString
            "2"
            nilString
        }
        let result = """
        families = [
            "1",
            "2",
        ],
        """
        #expect(property.text == result)
    }
}
