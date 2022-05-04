//
//  File.swift
//  
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj

public protocol File {
    var relativePath: String {get}
}

extension PBXFileElement: File {
    public var relativePath: String {
        var paths: [String?] = [self.path ?? self.name]
        var cursor: PBXFileElement? = self

        while let parent = cursor?.parent {
//        while let parent = cursor?.parent, parent.sourceTree != .sourceRoot {
            cursor = parent
            if parent.sourceTree == .sourceRoot || parent.sourceTree == .group {
                break
            }
            paths.append(parent.path ?? parent.name)
            
        }
        return paths
            .compactMap { $0 }
            .reversed()
            .joined(separator: "/")
    }
}

extension Array where Element == File {
    var paths: String {
        return self.map(\.relativePath).map { path in
            return """
                    "\(path)",
            """
        }.joined(separator: "\n")
    }
}
