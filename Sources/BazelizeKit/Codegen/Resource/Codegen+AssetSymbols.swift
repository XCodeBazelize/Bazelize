import BazelRules
import Foundation
import PathKit
import Starlark
import XCode2

/// `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
///
/// Xcode 15+ runs `actool` to turn every asset into a Swift member
/// (`ImageResource.icon`, `ColorResource.accent`, `Color.accent`, …) and compiles
/// the result into the target. Without it the sources referencing those members do
/// not build, so the same `actool` invocation is wired up as a `genrule`.
extension Target {
    // MARK: Internal

    static let assetSymbolsTarget = "AssetSymbols"
    static let assetSymbolsFile = "GeneratedAssetSymbols.swift"

    var assetSymbolSources: [Starlark.Label] {
        generatesAssetSymbols ? [.named(":\(Self.assetSymbolsTarget)")] : []
    }

    func generateAssetSymbols(_ builder: CodeBuilder, _: Kit) {
        guard generatesAssetSymbols else { return }

        builder.call(
            Rules.Builtin.Call.genrule(
                name: Self.assetSymbolsTarget,
                srcs: Starlark.glob(assets.map { "\($0)/**" }),
                outs: [Self.assetSymbolsFile],
                cmd: assetSymbolsCommand,
                visibility: .private))
    }

    // MARK: Private

    private var generatesAssetSymbols: Bool {
        guard prefer(\.assetCatalog.generatesSwiftSymbols) == true else { return false }
        return !assets.isEmpty
    }

    /// `actool` refuses to emit symbols without a bundle identifier, and it needs to
    /// know the platform it is compiling for. Catalog paths are derived from
    /// `$(SRCS)` so the command stays correct when a target carries several catalogs.
    ///
    /// Starlark rejects unknown escape sequences inside the string, so the command
    /// avoids backslashes entirely.
    private var assetSymbolsCommand: String {
        let bundleID = prefer(\.metadata.bundleID) ?? "com.bazelize.\(codegenModuleName)"
        let arguments = [
            "--platform \(assetSymbolsPlatform)",
            "--minimum-deployment-target \(assetSymbolsMinimumOS)",
            "--bundle-identifier \(bundleID)",
            "--output-format human-readable-text",
            "--generate-swift-asset-symbol-extensions YES",
        ].joined(separator: " ")

        return """
        set -e
        catalogs=$$(for src in $(SRCS); do echo "$${src%%.xcassets/*}.xcassets"; done | sort -u)
        compile=$$(mktemp -d)
        xcrun actool $$catalogs --compile "$$compile" \(arguments) --generate-swift-asset-symbols $@ > /dev/null
        """
    }

    private var assetSymbolsPlatform: String {
        switch platformSDK {
        case .macOS: return "macosx"
        case .tvOS: return "appletvos"
        case .watchOS: return "watchos"
        default: return "iphoneos"
        }
    }

    private var assetSymbolsMinimumOS: String {
        switch platformSDK {
        case .macOS: return prefer(\.platform.macOS) ?? "11.0"
        case .tvOS: return prefer(\.platform.tvOS) ?? "15.0"
        case .watchOS: return prefer(\.platform.watchOS) ?? "8.0"
        default: return prefer(\.platform.iOS) ?? "15.0"
        }
    }
}
