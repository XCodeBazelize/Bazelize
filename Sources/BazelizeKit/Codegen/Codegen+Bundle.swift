extension Target {
    func generateBundleProduct(_ builder: CodeBuilder, _ kit: Kit) {
        generateStrings(builder, kit)
        generateCopiedProducts(builder, kit)
        generateCopiedFiles(builder, kit)

        switch productType {
        case .bundle:
            generateMacOSBundle(builder, kit)
        case .xpcService:
            generateXPCService(builder, kit)
        case .appExtension, .tvExtension, .intentsServiceExtension:
            generateExtension(builder, kit)
        case .watch2Extension:
            generateWatchKitExtension(builder, kit)
        case .messagesExtension:
            generateIMessageExtension(builder, kit)
        case .stickerPack:
            generateStickerPack(builder, kit)
        default:
            break
        }
    }

    private func generateMacOSBundle(_ builder: CodeBuilder, _ kit: Kit) {
        builder.call(
            Rules.Apple.MacOS.Call.macos_bundle(
                name: name,
                additional_contents: additionalContents(project: kit.project),
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                },
                entitlements: entitlementsLabel(project: kit.project),
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.macOS),
                resources: .build {
                    bundleResources(project: kit.project)
                },
                strings: .build {
                    if !allStrings.isEmpty {
                        ":Strings"
                    }
                },
                visibility: .public))
    }
}
