import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fatalError("usage: StampTool <output> <target>")
}

let source = """
public let stamp = "stamped \(arguments[2])"

"""

try source.write(toFile: arguments[1], atomically: true, encoding: .utf8)
