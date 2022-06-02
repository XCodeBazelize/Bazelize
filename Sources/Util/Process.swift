//
//  Process.swift
//  
//
//  Created by Yume on 2022/4/26.
//

import Foundation

extension Process {
    private static var task: Process {
        var environment = ProcessInfo.processInfo.environment
        environment["LANG"] = "en_US.UTF-8"
        
        let task = Process()
        task.environment = environment
        return task
    }
    
    private func setup(_ command: String, arguments: [String]) {
        var args = command.split(separator: " ").map(String.init)
        let cmd = args.removeFirst()
        self.executableURL = URL(fileURLWithPath: cmd)
        self.arguments = args + arguments
        self.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }
    
    public static func execute(_ command: String, arguments: String...) async throws -> Data {
        let task = Process.task
        task.setup(command, arguments: arguments)
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        return try await withTaskCancellationHandler(operation: {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try task.run()
                    task.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }, onCancel: {
            task.terminate()
        })
    }
    
    public static func result(_ command: String, arguments: String...) -> Bool {
        let task = Process.task
        task.setup(command, arguments: arguments)

        task.standardError = Pipe()
        task.standardOutput = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
}
