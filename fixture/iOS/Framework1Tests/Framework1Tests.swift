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
        XCTAssertEqual(Framework1.test(), "Framework1+Swift")
        XCTAssertEqual(Framework1.test2(), "Framework2+Swift")
    }

    func testFramework2() throws {
        XCTAssertEqual(Framework2.test(), "Framework2+Swift")
    }
}
