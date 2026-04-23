//
//  StarlarkTests.swift
//
//
//  Created by Yume on 2022/8/18.
//

import Testing
@testable import RuleBuilder

// MARK: - StarlarkTests

struct StarlarkTests {
    func build(@StarlarkBuilder builder: () -> Starlark.Value) -> Starlark.Value {
        builder()
    }
}
