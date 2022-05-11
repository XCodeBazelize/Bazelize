//
//  Util.swift
//  
//
//  Created by Yume on 2022/5/11.
//

import Foundation

enum Util {
    /// AFNetworking
    ///     AFNetworking, AFNetworking
    ///
    /// AFNetworking/NSURLSession
    ///     AFNetworking, NSURLSession
    static func parse(name: String) -> (package: String, target: String) {
        let parts = name.split(separator: "/").map(String.init)
        switch parts.count {
        case 1:
            return (name, name)
        /// 2 up
        default:
            return (parts[0], parts[1])
        }
    }
}
