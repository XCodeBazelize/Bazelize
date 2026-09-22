//
//  Listing.swift
//
//
//  What a generated workspace can be asked about itself.
//

import Foundation
@preconcurrency import PathKit

// MARK: - Listing

/// The answers embedded in a generated workspace's listing executables.
///
/// Configuration files are read after generation, and trait state comes from
/// the same resolved workspace that generated the package rules.
enum Listing {
    /// The configurations this workspace defines, and what every build gets
    /// whether it names one or not.
    static func config(output: Path) throws -> String {
        let rc = try configurations(in: output)

        var lines: [String] = []
        if rc.configs.isEmpty {
            lines.append("This workspace defines no --config.")
        } else {
            lines.append("Configurations of this workspace, as `--config=<name>`:")
            lines.append("")
            for name in rc.configs.keys.sorted() {
                lines.append("  \(name)")
                for flag in rc.configs[name] ?? [] {
                    lines.append("    \(flag)")
                }
            }
        }

        guard !rc.always.isEmpty else { return lines.joined(separator: "\n") }

        lines.append("")
        lines.append("What every build gets, named or not:")
        lines.append("")
        for flag in rc.always {
            lines.append("  \(flag)")
        }
        return lines.joined(separator: "\n")
    }

    /// The traits of every package in the workspace, which of them a build gets
    /// by default, and what to say to change that.
    static func traits(workspace: SwiftPM.Workspace) -> String {
        let declaring = workspace.packages
            .filter { !$0.manifest.traits.isEmpty }
            .sorted { $0.directory < $1.directory }

        guard !declaring.isEmpty else {
            return "No package in this workspace declares a trait."
        }

        var lines = ["Traits of this workspace's packages:", ""]
        for package in declaring {
            let turnedOn = workspace.traits[package.identity] ?? []
            lines.append("  \(package.directory)")

            for trait in package.manifest.traits.sorted(by: { $0.name < $1.name }) {
                /// `default` is not a trait a target compiles with, it is the
                /// list of traits a build that asks for nothing gets.
                if trait.name == "default" {
                    let names = trait.enabledTraits.sorted().joined(separator: ", ")
                    lines.append("    default: \(names.isEmpty ? "none" : names)")
                    continue
                }

                let on = turnedOn.contains(trait.name)
                let enables = trait.enabledTraits.sorted().joined(separator: ", ")
                lines.append(
                    "    \(on ? "on " : "off") \(trait.name)"
                        + (enables.isEmpty ? "" : " (enables \(enables))")
                        + (on ? "" : "  --config=\(package.directory).\(trait.name)"))
            }
        }

        lines.append("")
        lines.append("""
        A trait is on by default when its package makes it one, or when \
        something that depends on that package asks for it by name. Anything \
        else is asked for by the `--config` beside it, which defines the \
        trait's own name for that package's sources and pulls in whatever is \
        behind it. `bazel run //tools:list-config` lists them with everything else.
        """)
        return lines.joined(separator: "\n")
    }

    /// What the workspace's `.bazelrc` says, and what the files it imports say:
    /// the `build:<name>` lines by name, and the ones that name no
    /// configuration.
    private static func configurations(
        in output: Path) throws -> (configs: [String: [String]], always: [String])
    {
        var configs: [String: [String]] = [:]
        var always: [String] = []

        for file in files(from: output + ".bazelrc", in: output) {
            guard let contents: String = try? file.read() else { continue }

            for line in contents.split(separator: "\n") {
                let statement = line.trimmingCharacters(in: .whitespaces)
                guard !statement.hasPrefix("#") else { continue }
                /// An import is how the file is put together, not something a
                /// build is given.
                guard !statement.hasPrefix("import "), !statement.hasPrefix("try-import ") else {
                    continue
                }

                let parts = statement.split(separator: " ", maxSplits: 1)
                guard
                    let command = parts.first,
                    let flags = parts.dropFirst().first?.trimmingCharacters(in: .whitespaces)
                else {
                    continue
                }

                let named = command.split(separator: ":", maxSplits: 1)
                if named.count == 2 {
                    configs[String(named[1]), default: []].append("\(named[0]): \(flags)")
                } else {
                    always.append("\(command): \(flags)")
                }
            }
        }

        return (configs, always)
    }

    /// A `.bazelrc` and the files it imports, which is where a generated
    /// workspace keeps most of what it defines.
    private static func files(from entry: Path, in output: Path) -> [Path] {
        guard entry.isFile, let contents: String = try? entry.read() else { return [] }

        var files = [entry]
        for line in contents.split(separator: "\n") {
            let statement = line.trimmingCharacters(in: .whitespaces)
            guard statement.hasPrefix("import ") || statement.hasPrefix("try-import ") else { continue }

            let path = statement
                .split(separator: " ", maxSplits: 1)[1]
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "%workspace%", with: output.string)
            files += self.files(from: Path(path), in: output)
        }
        return files
    }
}
