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
        guard let definitions = Bundle.module.url(
            forResource: "OptParser", withExtension: "td", subdirectory: "tds")
        else {
            throw ValidationError("Missing bundled tds/OptParser.td")
        }
        let table = try String(contentsOf: definitions, encoding: .utf8)
        guard table.contains("class Option<") else {
            throw ValidationError("Bundled OptParser.td does not declare Option")
        }
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
