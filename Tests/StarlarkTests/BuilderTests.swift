//
//  TextBuilderTests.swift
//
//
//  Created by Yume on 2022/7/29.
//

import Testing
@testable import Starlark

struct RuleTests {
    private static let target = """
    ios_framework(
        name = "Test",
        bundle_id = "com.example.test",
        families = [
            "1",
            "2",
        ],
    )
    """

    @Test
    func testStarlarkSimple() {
        let result = Starlark.Statement.Call("ios_framework") {
            "name" => "Test"
            "bundle_id" => "com.example.test"
            "families" => {
                "1"
                "2"
            }
        }.text
        #expect(result == Self.target)
    }

    @Test
    func testStarlarkArray() {
        let result = Starlark.Statement.Call("ios_framework") {
            "name" => "Test"
            "bundle_id" => "com.example.test"
            "families" => {
                ["1", "2"]
            }
        }.text
        #expect(result == Self.target)
    }

    @Test
    func testWithNil() {
        let nilStr: String? = nil

        let result = Starlark.Statement.Call("ios_framework") {
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
            # name = None,
            families = [
                "1",
                "2",
            ],
        )
        """
        #expect(result == target)
    }

    @Test
    func testWithComment() {
        let result = Starlark.Statement.Call("ios_framework") {
            Starlark.Statement.Argument.comment("Before")
            "name" => "Test"
            Starlark.Statement.Argument.comment("After")
        }.text

        let target = """
        ios_framework(
            # Before
            name = "Test",
            # After
        )
        """
        #expect(result == target)
    }

    @Test
    func testWithDictionary() {
        let result = Starlark.Statement.Call("ios_framework") {
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
        #expect(result == target)
    }

    @Test
    func testWithBool() {
        let result = Starlark.Statement.Call("ios_framework") {
            "data1" => true
            "data2" => false
        }.text

        let target = """
        ios_framework(
            data1 = True,
            data2 = False,
        )
        """
        #expect(result == target)
    }

    @Test
    func testWithNone() {
        let result = Starlark.Statement.Call("ios_framework") {
            "data" => None
        }.text

        let target = """
        ios_framework(
            # data = None,
        )
        """
        #expect(result == target)
    }

    @Test
    func testWithEmptyDictionary() {
        let result = Starlark.Statement.Call("ios_framework") {
            "data" => [:]
        }.text

        let target = """
        ios_framework(
            data = {
            },
        )
        """
        #expect(result == target)
    }
}
