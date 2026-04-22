//
//  StarlarkTests.swift
//
//
//  Created by Yume on 2022/8/18.
//

import XCTest
@testable import RuleBuilder

// MARK: - StarlarkTests

final class StarlarkTests: XCTestCase {
    func build(@StarlarkBuilder builder: () -> Starlark.Value) -> Starlark.Value {
        builder()
    }
}
