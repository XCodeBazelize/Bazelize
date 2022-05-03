//
//  File.swift
//  
//
//  Created by Yume on 2022/4/26.
//

import Foundation

//if #available(macOS 10.13, *) {
//    process.executableURL = URL(fileURLWithPath: command)
//    process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
//    try process.run()
//} else {
//    process.launchPath = command
//    process.currentDirectoryPath = currentDirectory
//    process.launch()
//}

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
//        task.launchPath = command
//        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                continuation.resume(returning: data)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    public static func result(_ command: String, arguments: String...) -> Bool {
        let task = Process.task
        task.setup(command, arguments: arguments)
//        task.launchPath = command
//        task.arguments = arguments
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
//
//
//protocol Command {
//    var launchPath: String { get }
////    var subCommand: String? { get }
////    var arguments: [String] { get }
//}
//
//protocol ArgumentsCommand {
//    associatedtype _Command: Command
//    var command: _Command { get }
//    var subCommand: String? { get }
//    var arguments: [String] { get }
//}
//
//extension ArgumentsCommand {
//    var data: AnyPublisher<Data, Error> {
//        return Process
//            .execute(self.command.launchPath, arguments: self.arguments)
//            .receive(on: RunLoop.main)
//            .eraseToAnyPublisher()
//    }
//
//    var text: AnyPublisher<String, Error> {
//        return self.data.compactMap { (data: Data) -> String? in
//            return String.init(data: data, encoding: .utf8)
//        }.eraseToAnyPublisher()
//    }
//
//    func json<T: Decodable>(decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, Error> {
//        return self.data.tryMap { (data) -> T in
//            return try decoder.decode(T.self, from: data)
//        }.eraseToAnyPublisher()
//    }
//}
//
//
//class CommandController: ObservableObject {
//
//}
//
//enum Mint {
//    static var command = Commands.mint
//
//    static var list = _ArgumentsCommand(command: command, arguments: ["list"])
//    static var version = _ArgumentsCommand(command: command, arguments: ["version"])
//}
//
//
//struct _Command: Command, ExpressibleByStringLiteral {
//
//    let launchPath: String
//
//    init(launchPath value: String) {
//        self.launchPath = value
//    }
//
//    init(stringLiteral value: String) {
//        self.launchPath = value
//    }
//}
//
//enum Commands {
//    static let mint: _Command = "/usr/local/bin/mint"
//}
//
//struct _ArgumentsCommand<C: Command>: ArgumentsCommand {
//    let command: C
//    let subCommand: String?
//    let arguments: [String]
//
//    init(command: C, subCommand: String? = nil, arguments: [String]) {
//        self.command = command
//        self.subCommand = subCommand
//        self.arguments = arguments
//    }
//}
