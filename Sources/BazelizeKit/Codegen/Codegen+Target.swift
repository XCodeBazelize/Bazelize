import Util

extension Target {
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
