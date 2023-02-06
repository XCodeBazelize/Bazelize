//
//  Test.swift
//  Framework1
//
//  Created by Yume on 2023/1/10.
//

import Foundation
import Framework2
import Static

public enum Framework1 {
    public static func test() -> String {
        "Framework1+Swift"
    }

    public static func test2() -> String {
        Framework2.test()
    }

    public static func test3() -> String {
        Static.test()
    }
}
