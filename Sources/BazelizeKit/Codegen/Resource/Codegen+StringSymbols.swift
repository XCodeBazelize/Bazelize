import BazelRules
import Foundation
import PathKit
import Starlark
import Xcode

/// `STRING_CATALOG_GENERATE_SYMBOLS`
///
/// Xcode 26+ runs `xcstringstool generate-symbols` over every `.xcstrings` table a
/// target owns and compiles the result into it, which is where members like
/// `LocalizedStringResource.ok` come from. Without them the sources referencing
/// those members do not build — and because the references sit inside SwiftUI view
/// builders, the type checker gives up on whole bodies rather than naming the
/// missing member, so the same tool is wired up as a `genrule`.
extension Target {
    // MARK: Internal

    static let stringSymbolsTarget = "StringSymbols"

    var stringSymbolSources: [Starlark.Label] {
        generatesStringSymbols ? [.named(":\(Self.stringSymbolsTarget)")] : []
    }

    func generateStringSymbols(_ builder: CodeBuilder, _: Kit) {
        guard generatesStringSymbols else { return }

        builder.call(
            Rules.Builtin.Call.genrule(
                name: Self.stringSymbolsTarget,
                srcs: Starlark.paths(symbolicStringCatalogs),
                outs: symbolicStringCatalogs.map(Self.stringSymbolsFile),
                cmd: stringSymbolsCommand,
                visibility: .private))
    }

    // MARK: Private

    /// `xcstringstool` names its output after the table, and a table is named after
    /// the file. Two catalogs of the same name would claim the same output, which is
    /// also what Xcode refuses to build, so the first one to claim a name keeps it.
    private var symbolicStringCatalogs: [String] {
        var seen: Set<String> = []
        return stringCatalogs.filter { catalog in
            seen.insert(Path(catalog).lastComponentWithoutExtension).inserted
        }
    }

    private static func stringSymbolsFile(of catalog: String) -> String {
        "GeneratedStringSymbols_\(Path(catalog).lastComponentWithoutExtension).swift"
    }

    private var generatesStringSymbols: Bool {
        guard prefer(\.stringCatalog.generatesSymbols) == true else { return false }
        return !symbolicStringCatalogs.isEmpty
    }

    /// The tool takes one catalog per run and writes into a directory, which for a
    /// `genrule` is `$(RULEDIR)`. Each path is spelled out through `$(location …)`
    /// rather than taken from `$(SRCS)`: a localizable file commonly lives in a
    /// directory with a space in its name, `$(SRCS)` is a space-separated list, and
    /// `$(location …)` is the one expansion Bazel quotes for the shell itself.
    private var stringSymbolsCommand: String {
        let runs = symbolicStringCatalogs.map { catalog in
            """
            xcrun xcstringstool generate-symbols $(location \(catalog)) \
            --output-directory "$(RULEDIR)" --language swift
            """
        }

        return (["set -e"] + runs).joined(separator: "\n")
    }
}
