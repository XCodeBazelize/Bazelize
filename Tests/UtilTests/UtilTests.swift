//
//  SPMTests.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import Testing
@testable import Util

struct UtilTests {
    @Test
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

        #expect(origin.indent(1, " ") == result)
    }

    @Test
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

        #expect(origin.indent(2, " ") == result)
    }

    @Test
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

        #expect(origin.indent(2, " ") == result)
    }
}
