//
//  Framework1Tests.swift
//  Framework1Tests
//
//  Created by Yume on 2023/1/10.
//

import AVFoundation
import Framework2
import Static
import XCTest
@testable import Framework1

final class Framework1Tests: XCTestCase {
    func testFramework1() throws {
        XCTAssertEqual(test1(), 1)
        XCTAssertEqual(test4(), 4)
    }

    func testFramework2() throws {
        XCTAssertEqual(test2(), 2)
    }
}
