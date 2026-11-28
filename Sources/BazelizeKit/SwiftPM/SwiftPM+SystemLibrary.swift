//
//  SwiftPM+SystemLibrary.swift
//
//
//  Rules for a package target that wraps a library the system already has.
//

import BazelRules
import Commands
import Foundation
@preconcurrency import PathKit
import Starlark
import Util
import Xcode

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
        builder: CodeBuilder) async
        -> Bool
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
        let pkgConfig = await pkgConfig(of: target, in: package)
        /// An include path of the machine's is linked into the workspace, so
        /// what the module needs is a directory of this build rather than a
        /// path only this machine has — and `includes` reaches whoever imports
        /// the module, which `copts` would not.
        let included = (try? materialize(
            includePaths: pkgConfig.includePaths,
            of: target,
            at: root)) ?? []

        builder.call(
            Rules.Swift.Call.swift_interop_hint(
                name: hint,
                module_map: .named(moduleMap),
                module_name: Self.moduleName(target.name)))

        builder.call(
            Rules.Cc.Call.cc_library(
                name: name,
                aspect_hints: .build { [Starlark.Label.named(":\(hint)")] },
                hdrs: (matching(Self.headerExtensions.map { "\(prefix)/**/*.\($0.rawValue)" }, files)
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
        at root: Path) throws
        -> [String]
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
        in package: SwiftPM.Package) async
        -> PkgConfig
    {
        guard let name = target.pkgConfig else { return .none }

        guard
            let compilerFlags = try? await Commands.pkgConfig.pkgConfigCFlags(package: name),
            let linkerFlags = try? await Commands.pkgConfig.pkgConfigLinkerFlags(package: name)
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

        return PkgConfig(compilerFlags: compilerFlags, linkerFlags: linkerFlags)
    }

    private enum CompilerOption: String {
        case include = "-I"
        case define = "-D"

        init?(argument: String) {
            if argument.hasPrefix(Self.include.rawValue) {
                self = .include
            } else if argument.hasPrefix(Self.define.rawValue) {
                self = .define
            } else {
                return nil
            }
        }
    }

    /// An include path reaches whoever imports the module, a define reaches
    /// them too, and anything else is only this module's to compile with.
    struct PkgConfig {
        init(compilerFlags: [String], linkerFlags: [String]) {
            self.linkerFlags = linkerFlags
            var pending: CompilerOption?

            for flag in compilerFlags {
                let option: CompilerOption
                let value: String
                if let waiting = pending {
                    option = waiting
                    value = flag
                    pending = nil
                } else if let parsed = CompilerOption(argument: flag) {
                    if flag == parsed.rawValue {
                        pending = parsed
                        continue
                    }
                    option = parsed
                    value = String(flag.dropFirst(parsed.rawValue.count))
                } else {
                    otherFlags.append(flag)
                    continue
                }

                switch option {
                case .include:
                    includePaths.append(value)
                case .define:
                    defines.append(value)
                }
            }
        }

        var includePaths: [String] = []
        var defines: [String] = []
        var otherFlags: [String] = []
        var linkerFlags: [String]

        static let none = PkgConfig(compilerFlags: [], linkerFlags: [])
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
