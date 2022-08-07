//
//  SPMTests.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XCTest
@testable import Util

final class UtilTests: XCTestCase {
    func testIndent1() throws {
        let origin = """
            1
            2
            3
            """
        let result = """
             1
             2
             3
            """

        XCTAssertEqual(origin.indent(1, " "), result)
    }

    func testIndent2() throws {
        let origin = """
            1
            2
            3
            """
        let result = """
              1
              2
              3
            """

        XCTAssertEqual(origin.indent(2, " "), result)
    }

    func testIndent2_1() throws {
        let origin = """
            1
              2
                3
            """
        let result = """
              1
                2
                  3
            """

        XCTAssertEqual(origin.indent(2, " "), result)
    }
}
