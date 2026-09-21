import Foundation
import ArgumentParser
import TbParser

@main
struct Command: AsyncParsableCommand {
    @Option(
        name: [.short],
        help: "Input .tb file"
    )
    var input: URL
    
    @Option(
        name: [.short],
        help: "Output .swift file"
    )
    var output: URL
    
    @Option(
        name: [.customLong("name")],
        help: "Output enum name"
    )
    var name: String
    
    func run() async throws {
        let code = try String(contentsOf: input)
        let result = try CodeGenerater.generate(name: name, content: code)
        try result.write(to: output, atomically: true, encoding: .utf8)
    }
}

extension URL: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        self.init(filePath: argument)
    }
}
