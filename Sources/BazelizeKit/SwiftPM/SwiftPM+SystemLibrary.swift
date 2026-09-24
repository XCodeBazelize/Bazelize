//
//  SwiftPM+SystemLibrary.swift
//
//
//  Rules for a package target that wraps a library the system already has.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// A system-library target is a module map over headers that are already on
    /// the machine, so the rule compiles nothing and only says what to link.
    ///
    /// The module map is the whole interface: it names the headers and, through
    /// its `link` directives, the libraries and frameworks the module needs.
    func buildSystemLibrary(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        root: Path,
        builder: CodeBuilder) -> Bool
    {
        let moduleMap = "\(prefix)/module.modulemap"
        guard (root + moduleMap).exists else {
            Log.codeGenerate.warning("""
            Skip \(package.directory, privacy: .public)/\(target.name, privacy: .public): \
            a system library target without a module map
            """)
            return false
        }

        let name = ruleName(of: target.name, in: package)
        let hint = "\(name)_interop"
        let files = relativeFiles(of: target, in: package, prefix: prefix)
        let pkgConfig = self.pkgConfig(of: target, in: package)
        /// An include path of the machine's is linked into the workspace, so
        /// what the module needs is a directory of this build rather than a
        /// path only this machine has — and `includes` reaches whoever imports
        /// the module, which `copts` would not.
        let included = (try? materialize(
            includePaths: pkgConfig.includePaths,
            of: target,
            at: root)) ?? []

        builder.load(loadableRule: Rules.Swift.swift_interop_hint)
        builder.call(
            Rules.Swift.Call.swift_interop_hint(
                name: hint,
                module_map: .named(moduleMap),
                module_name: Self.moduleName(target.name)))

        builder.load(loadableRule: Rules.Cc.cc_library)
        builder.call(
            Rules.Cc.Call.cc_library(
                name: name,
                aspect_hints: .build { [Starlark.Label.named(":\(hint)")] },
                hdrs: (matching(Self.headerExtensions.map { "\(prefix)/**/*.\($0)" }, files)
                    + included.map { "\($0)/**" })
                    .nonEmpty
                    .map { Starlark.glob($0) },
                copts: pkgConfig.otherFlags.nonEmpty?.starlark,
                defines: pkgConfig.defines.nonEmpty,
                includes: [prefix] + included,
                /// What the module map names, and what `pkg-config` says: a
                /// library installed somewhere of its own is only found through
                /// the second, and both usually name the same `-l`.
                linkopts: Self.deduplicated(
                    Self.linkopts(moduleMap: root + moduleMap) + pkgConfig.linkerFlags).starlark,
                tags: Self.manual,
                visibility: .public))

        return true
    }

    /// One link per include path `pkg-config` reported, under the target's own
    /// artifact directory, answering where they sit in the workspace.
    private func materialize(
        includePaths: [String],
        of target: SwiftPM.PackageTarget,
        at root: Path) throws -> [String]
    {
        guard !includePaths.isEmpty else { return [] }

        let directory = root + Self.artifactsRoot + target.name
        try directory.mkpath()

        return try includePaths.enumerated().compactMap { index, path in
            let source = Path(path).normalize()
            guard source.isDirectory else { return nil }

            let relative = "\(Self.artifactsRoot)/\(target.name)/include\(index)"
            let link = root + relative
            if link.isSymlink || link.exists { try? link.delete() }
            try link.symlink(source)

            return relative
        }
    }

    /// Linker flags with the repeats dropped, in the order they were given.
    ///
    /// `-framework` takes what follows it, so flags are compared in the groups
    /// they are passed in rather than one word at a time.
    private static func deduplicated(_ flags: [String]) -> [String] {
        var groups: [[String]] = []
        var index = flags.startIndex

        while index < flags.endIndex {
            let flag = flags[index]
            let takesValue = flag == "-framework" || flag == "-weak_framework" || flag == "-Xlinker"

            if takesValue, flags.index(after: index) < flags.endIndex {
                groups.append([flag, flags[flags.index(after: index)]])
                index = flags.index(index, offsetBy: 2)
            } else {
                groups.append([flag])
                index = flags.index(after: index)
            }
        }

        var seen: Set<[String]> = []
        return groups.filter { seen.insert($0).inserted }.flatMap { $0 }
    }

    /// What `pkg-config` says about the library a target wraps, split the way
    /// the rule takes it.
    ///
    /// SwiftPM asks the same question and for the same reason: a module map
    /// names a header and a library, and only the machine knows where either
    /// one is. When the answer is missing, the providers the manifest names are
    /// what installs it, so that is what the note says.
    private func pkgConfig(
        of target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package) -> PkgConfig
    {
        guard let name = target.pkgConfig else { return .none }

        guard let compilerFlags = Self.pkgConfig(["--cflags", name]),
              let linkerFlags = Self.pkgConfig(["--libs", name])
        else {
            let installs = target.providers
                .map { "\($0.manager) \($0.packages.joined(separator: " "))" }
                .joined(separator: ", ")

            note("""
            \(package.directory)/\(target.name) wraps the \(name) library, which \
            pkg-config does not know about: what its module map names is all the \
            build has.\(installs.isEmpty ? "" : " The package says it comes from: \(installs).")
            """)
            return .none
        }

        var pkgConfig = PkgConfig(linkerFlags: linkerFlags)
        var pending: String?

        for flag in compilerFlags {
            if let waiting = pending {
                if waiting == "-I" { pkgConfig.includePaths.append(flag) } else { pkgConfig.defines.append(flag) }
                pending = nil
                continue
            }

            switch true {
            case flag == "-I", flag == "-D":
                pending = flag
            case flag.hasPrefix("-I"):
                pkgConfig.includePaths.append(String(flag.dropFirst(2)))
            case flag.hasPrefix("-D"):
                pkgConfig.defines.append(String(flag.dropFirst(2)))
            default:
                pkgConfig.otherFlags.append(flag)
            }
        }

        return pkgConfig
    }

    /// An include path reaches whoever imports the module, a define reaches
    /// them too, and anything else is only this module's to compile with.
    private struct PkgConfig {
        var includePaths: [String] = []
        var defines: [String] = []
        var otherFlags: [String] = []
        var linkerFlags: [String] = []

        static let none = PkgConfig()
    }

    /// One `pkg-config` question, or `nil` when it cannot be answered.
    private static func pkgConfig(_ arguments: [String]) -> [String]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["pkg-config"] + arguments

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        return String(data: data, encoding: .utf8)?
            .split(whereSeparator: \.isWhitespace)
            .map(String.init) ?? []
    }

    /// `link "z"` and `link framework "Cocoa"` in a module map are what the module
    /// needs at link time; nothing else in the manifest says so.
    static func linkopts(moduleMap: Path) -> [String] {
        guard let content: String = try? moduleMap.read() else { return [] }

        var linkopts: [String] = []
        for line in content.split(separator: "\n") {
            let statement = line.trimmingCharacters(in: .whitespaces)
            guard statement.hasPrefix("link ") else { continue }

            guard let name = statement.split(separator: "\"").dropFirst().first else { continue }
            if statement.hasPrefix("link framework") {
                linkopts.append(contentsOf: ["-framework", String(name)])
            } else {
                linkopts.append("-l\(name)")
            }
        }

        return linkopts
    }
}
