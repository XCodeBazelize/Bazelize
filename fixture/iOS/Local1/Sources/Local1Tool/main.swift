import Foundation

/// A tool the package builds, which is what a build tool plugin runs.
///
/// Without arguments it is just a command line tool, which is what the binary
/// rule for it builds; with them it writes the files the plugin declared as its
/// outputs.
func argument(_ name: String) -> String? {
    guard let index = CommandLine.arguments.firstIndex(of: name) else { return nil }
    let value = CommandLine.arguments.index(after: index)
    return value < CommandLine.arguments.endIndex ? CommandLine.arguments[value] : nil
}

guard let output = argument("--output"), let kind = argument("--kind") else {
    print("Local1Tool")
    exit(0)
}

let directory = URL(fileURLWithPath: output, isDirectory: true)

func write(_ contents: String, to name: String) throws {
    try contents.write(
        to: directory.appendingPathComponent(name),
        atomically: true,
        encoding: .utf8)
}

switch kind {
case "clang":
    try write(
        """
        int local1_plugin_value(void);
        """,
        to: "LocalTarget3Generated.h")
    try write(
        """
        #include "LocalTarget3Generated.h"

        int local1_plugin_value(void) {
            return 42;
        }
        """,
        to: "LocalTarget3Generated.c")
default:
    try write(
        """
        /// Written by the Local1Gen build tool plugin.
        public enum Local1Generated {
            public static let value = 42
        }
        """,
        to: "Local1Generated.swift")
    try write(
        """
        {"generatedBy": "Local1Gen"}
        """,
        to: "local1-generated.json")
}
