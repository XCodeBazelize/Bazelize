extension Target {
    func generateBundleProduct(_ builder: CodeBuilder, _ kit: Kit) {
        generateStrings(builder, kit)
        generateCopiedProducts(builder, kit)
        generateCopiedFiles(builder, kit)

        switch productType {
        case "com.apple.product-type.bundle":
            generateMacOSBundle(builder, kit)
        case "com.apple.product-type.xpc-service":
            generateXPCService(builder, kit)
        case "com.apple.product-type.app-extension":
            generateExtension(builder, kit)
        default:
            break
        }
    }

    private func generateMacOSBundle(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.macos_bundle)
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
