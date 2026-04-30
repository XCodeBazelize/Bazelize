import Util

extension Target {
    func generateCode(_ kit: Kit) -> String {
        let builder = CodeBuilder()
        generateLibrary(builder, kit)

        generateLoadPlistFragment(builder, kit)
        generatePlistFile(builder, kit)
        generatePlistAuto(builder, kit)
        generatePlistDefault(builder, kit)

        let name = name

        switch productType {
        case "com.apple.product-type.application":
            generateStrings(builder, kit)
            generateApplicationCode(builder, kit)
        case "com.apple.product-type.tool":
            generateCommandLineApplicationCode(builder, kit)
        case "com.apple.product-type.framework":
            generateFrameworkCode(builder, kit)
        case "com.apple.product-type.library.static":
            generateStaticLibrary(builder, kit)
        case "com.apple.product-type.bundle.unit-test":
            generateUnitTest(builder, kit)
        case "com.apple.product-type.bundle.ui-testing":
            generateUITest(builder, kit)
        default:
            Log.codeGenerate.warning("""
            Name: \(name, privacy: .public)
            Type: \(productType ?? "") not gen
            """)
        }
        return builder.build()
    }
}
