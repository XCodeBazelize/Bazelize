import BazelRules
import Foundation
import PathKit
import Starlark
import Xcode

/// `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
///
/// Xcode 15+ runs `actool` to turn every asset into a Swift member
/// (`ImageResource.icon`, `ColorResource.accent`, `Color.accent`, …) and compiles
/// the result into the target. Without it the sources referencing those members do
/// not build, so the same `actool` invocation is wired up as a rule of the
/// workspace's own — `tools/asset_symbols.bzl`, which runs it as an Apple action.
extension Target {
    // MARK: Internal

    static let assetSymbolsTarget = "AssetSymbols"

    var assetSymbolSources: [Starlark.Label] {
        generatesAssetSymbols ? [.named(":\(Self.assetSymbolsTarget)")] : []
    }

    func generateAssetSymbols(_ builder: CodeBuilder, _: Kit) {
        guard generatesAssetSymbols else { return }

        builder.load(loadableRule: Rules.Workspace.asset_symbols)
        builder.call(
            Rules.Workspace.Call.asset_symbols(
                name: Self.assetSymbolsTarget,
                catalogs: Starlark.glob(assets.map { "\($0)/**" }),
                bundle_id: assetSymbolsBundleID,
                minimum_os_version: assetSymbolsMinimumOS,
                platform: assetSymbolsPlatform,
                visibility: .private))
    }

    // MARK: Private

    private var generatesAssetSymbols: Bool {
        guard prefer(\.assetCatalog.generatesSwiftSymbols) == true else { return false }
        return !assets.isEmpty
    }

    /// `actool` refuses to emit symbols without a bundle identifier, and one that
    /// still references a build setting Xcode would have expanded is no use to it.
    private var assetSymbolsBundleID: String {
        let resolved = (prefer(\.metadata.bundleID) ?? "")
            .resolvingBuildSettingReferences(with: selectedSettings, reserved: [])
        let fallback = "com.bazelize.\(codegenModuleName)"
        return resolved.isEmpty || resolved.contains("$") ? fallback : resolved
    }

    /// What the project was read as. The rule prefers the platform of the
    /// configuration it is built in and only falls back to this.
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
