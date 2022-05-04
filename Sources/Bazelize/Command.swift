//
//  File.swift
//  
//
//  Created by Yume on 2022/4/28.
//

import Foundation
import ArgumentParser
import PathKit
import BazelizeKit

struct Command: AsyncParsableCommand {
    @Option(name: [.customLong("project", withSingleDash: false)], help: "PATH/TO/YOUR.xcodeproj")
    var project: String
    
    @Option(name: [.short], help: "Debug/Release")
    var config: String = "Release"
    
    func run() async throws {
        let path = Path.current + project
        try await Kit(path).run()
    }
}
