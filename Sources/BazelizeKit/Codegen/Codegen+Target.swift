import Util

extension Target {
    /// A target's library is compiled through the bundle rule that transitions it
    /// to the target's platform. On its own it would be compiled for the host,
    /// which is not what an iOS target's sources are written against, so no
    /// wildcard pattern may pick one up.
    var manual: [String] {
        ["manual"]
    }
    /// A target with no sources of its own has no library to link, so no rule can
    /// produce its product: UTM wraps an externally built binary in a bundle that
    /// way. Nothing references a rule that is not emitted either.
    var hasSources: Bool {
        !(srcs_c + srcs_cpp + srcs_objc + srcs_objcpp + srcs_swift).isEmpty
    }

    func generateCode(_ kit: Kit) -> String {
        let builder = CodeBuilder()
        generateIntentLibraries(builder, kit)
        generateAssetSymbols(builder, kit)
        generateCopiedResourceGroup(builder, kit)
        generateLibrary(builder, kit)

        generateLoadPlistFragment(builder, kit)
        generatePlistFile(builder, kit)
        generatePlistAuto(builder, kit)
        generatePlistDefault(builder, kit)

        let name = name

        guard hasSources else {
            Log.codeGenerate.warning("""
            Name: \(name, privacy: .public)
            Type: \(productType ?? "") has no sources
            """)
            return builder.build()
        }

        switch productType {
        case "com.apple.product-type.application":
            generateStrings(builder, kit)
            generateCopiedProducts(builder, kit)
            generateCopiedFiles(builder, kit)
            generateApplicationCode(builder, kit)
        case "com.apple.product-type.tool":
            generateCommandLineApplicationCode(builder, kit)
        case "com.apple.product-type.framework":
            generateStrings(builder, kit)
            generateFrameworkCode(builder, kit)
        case "com.apple.product-type.library.static":
            generateStaticLibrary(builder, kit)
        case "com.apple.product-type.bundle.unit-test":
            generateUnitTest(builder, kit)
        case "com.apple.product-type.bundle.ui-testing":
            generateUITest(builder, kit)
        case "com.apple.product-type.xpc-service":
            generateStrings(builder, kit)
            generateCopiedProducts(builder, kit)
            generateCopiedFiles(builder, kit)
            generateXPCService(builder, kit)
        case "com.apple.product-type.app-extension":
            generateStrings(builder, kit)
            generateCopiedProducts(builder, kit)
            generateCopiedFiles(builder, kit)
            generateExtension(builder, kit)
        default:
            Log.codeGenerate.warning("""
            Name: \(name, privacy: .public)
            Type: \(productType ?? "") not gen
            """)
        }
        return builder.build()
    }
}
