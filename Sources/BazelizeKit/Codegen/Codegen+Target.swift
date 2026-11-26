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

    /// A sticker pack and an iMessage app ship what they carry rather than code
    /// of their own, so no library is what they are bundled from.
    var bundlesWithoutSources: Bool {
        productType == .stickerPack || productType == .messagesApplication
    }

    /// Whether a rule is written for the target's product.
    var isGenerated: Bool {
        hasSources || bundlesWithoutSources
    }

    func generateCode(_ kit: Kit) throws -> String {
        let builder = CodeBuilder()
        generateIntentLibraries(builder, kit)
        generateAssetSymbols(builder, kit)
        generateStringSymbols(builder, kit)
        generateCopiedResourceGroup(builder, kit)
        generateLibrary(builder, kit)

        generateLoadPlistFragment(builder, kit)
        generatePlistFile(builder, kit)
        generatePlistAuto(builder, kit)
        generatePlistDefault(builder, kit)

        let name = name

        guard isGenerated else {
            kit.note("""
            \(name) is not generated: a \(productType?.rawValue ?? "target") with no sources of its own \
            has no library for a rule to bundle.
            """)
            return builder.build()
        }

        switch productType {
        case .application:
            generateStrings(builder, kit)
            generateCopiedProducts(builder, kit)
            generateCopiedFiles(builder, kit)
            try generateApplicationCode(builder, kit)
        case .onDemandInstallCapableApplication:
            generateStrings(builder, kit)
            generateCopiedProducts(builder, kit)
            generateCopiedFiles(builder, kit)
            generateAppClip(builder, kit)
        case .messagesApplication:
            generateStrings(builder, kit)
            generateIMessageApplication(builder, kit)
        case .bundle, .xpcService, .appExtension, .tvExtension, .messagesExtension, .stickerPack:
            generateBundleProduct(builder, kit)
        case .commandLineTool:
            generateCommandLineApplicationCode(builder, kit)
        case .framework, .staticFramework:
            generateFrameworkProduct(builder, kit)
        case .staticLibrary:
            generateStaticLibrary(builder, kit)
        case .unitTestBundle:
            generateUnitTest(builder, kit)
        case .uiTestBundle:
            generateUITest(builder, kit)
        default:
            /// A product type nothing here knows is not a target to skip: whatever
            /// the project builds from it would be missing from every build that
            /// followed, and the error naming it is the only chance to notice.
            throw UnsupportedTarget.productType(target: name, productType: productType?.rawValue)
        }
        return builder.build()
    }
}

// MARK: - UnsupportedTarget

/// What the project asks for and this generator has no rule for. Generation
/// stops: a workspace missing a target is a workspace that builds the wrong
/// thing.
enum UnsupportedTarget: LocalizedError, CustomStringConvertible {
    case productType(target: String, productType: String?)
    case applicationPlatform(target: String, sdk: String?)

    var errorDescription: String? { description }

    var description: String {
        switch self {
        case .productType(let target, let productType):
            return """
            \(target): \(productType ?? "a target with no product type") is a product type \
            bazelize has no rule for.
            """
        case .applicationPlatform(let target, let sdk):
            return """
            \(target): an application for \(sdk ?? "no SDK of its own") is a platform \
            bazelize has no application rule for.
            """
        }
    }
}
