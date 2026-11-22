import Foundation

/// A target keeps its public module and label; private C-family groups only
/// contribute objects. ARC-only overrides use the rules' non_arc_srcs instead.
struct FileCompilerPlan {
    struct Group {
        let flags: [String]
        var sources: [String]
        var nonArcSources: [String]
    }

    var sources: [String]
    var nonArcSources: [String] = []
    var groups: [Group] = []
}

extension Target {
    func fileCompilerPlan(_ kit: Kit) -> FileCompilerPlan {
        let clang = srcs_c + srcs_cpp + srcs_objc + srcs_objcpp
        let clangPaths = Set(clang)
        let objcPaths = Set(srcs_objc + srcs_objcpp)
        let mixed = !srcs_swift.isEmpty
        var plan = FileCompilerPlan(sources: clang)
        var grouped: [[String]: FileCompilerPlan.Group] = [:]
        var relocated = Set<String>()

        for file in files.sources {
            guard let raw = file.compilerFlags, let path = file.path else { continue }
            let flags = Self.fileCompilerArguments(raw)
            guard !flags.isEmpty else { continue }
            let source = "Sources/\(path)"
            let arcFlags = ["-fobjc-arc", "-fno-objc-arc"]
            let arcOnly = objcPaths.contains(source) && flags.allSatisfy(arcFlags.contains)
            let unsupported = !clangPaths.contains(source) || (mixed && !arcOnly)
                || flags.contains { $0.contains("$(") || $0.contains("${") }
            if unsupported {
                for flag in flags {
                    kit.note("\(name): \(path): per-file compiler flag \(flag) is not representable in this module and is left out.")
                }
                continue
            }
            let noArc = objcPaths.contains(source) && flags.last(where: arcFlags.contains) == "-fno-objc-arc"
            if arcOnly {
                if noArc {
                    plan.nonArcSources.append(source)
                    relocated.insert(source)
                }
                continue
            }
            var group = grouped[flags] ?? .init(flags: flags, sources: [], nonArcSources: [])
            if noArc { group.nonArcSources.append(source) } else { group.sources.append(source) }
            grouped[flags] = group
            relocated.insert(source)
        }
        plan.sources.removeAll { relocated.contains($0) }
        plan.groups = grouped.values.sorted { $0.flags.lexicographicallyPrecedes($1.flags) }
        return plan
    }

    /// PBX COMPILER_FLAGS is a shell argument string. Keep quoted spaces and
    /// escapes; copts will receive each argument quoted for Bazel's own tokenizer.
    private static func fileCompilerArguments(_ value: String) -> [String] {
        var result: [String] = []
        var token = ""
        var quote: Character?
        var escaped = false
        var started = false
        for character in value {
            if escaped {
                token.append(character)
                escaped = false
            } else if character == "\\" && quote != "'" {
                escaped = true
                started = true
            } else if let current = quote {
                if character == current { quote = nil } else { token.append(character) }
            } else if character == "\"" || character == "'" {
                quote = character
                started = true
            } else if character.isWhitespace {
                if started { result.append(token) }
                token = ""
                started = false
            } else {
                token.append(character)
                started = true
            }
        }
        if escaped { token.append("\\") }
        if started { result.append(token) }
        return result.filter { !$0.isEmpty && $0 != "$(inherited)" }
    }
}

extension FileCompilerPlan.Group {
    var copts: [String] {
        flags.filter { $0 != "-fobjc-arc" && $0 != "-fno-objc-arc" }.map {
            "'" + $0.replacingOccurrences(of: "'", with: "'\\''") + "'"
        }
    }
}
