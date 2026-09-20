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
                hdrs: matching(Self.headerExtensions.map { "\(prefix)/**/*.\($0)" }, files)
                    .nonEmpty
                    .map { Starlark.glob($0) },
                includes: [prefix],
                linkopts: Self.linkopts(moduleMap: root + moduleMap).nonEmpty,
                tags: Self.manual,
                visibility: .public))

        return true
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
