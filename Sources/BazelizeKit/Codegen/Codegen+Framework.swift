// TODO: https://github.com/XCodeBazelize/Bazelize/issues/8 framework(static/dynamic)

extension Target {
    func generateFrameworkCode(_ builder: CodeBuilder, _ kit: Kit) {
        switch platformSDK {
        case .macOS: buildMacFramework(builder, kit)
        default: buildIOSFramework(builder, kit)
        }
    }

    private func buildIOSFramework(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.ios_framework)
        builder.call(
            Rules.Apple.IOS.Call.ios_framework(
                name: name,
                bundle_id: prefer(\.metadata.bundleID),
                /// Only the target's own code: a sibling framework is linked through
                /// its library, never nested inside this bundle.
                deps: .build {
                    ":\(name)_library"
                },
                families: prefer(\.platform.deviceFamily)?.map(\.code),
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.iOS),
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

    private func buildMacFramework(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.macos_framework)
        builder.call(
            Rules.Apple.MacOS.Call.macos_framework(
                name: name,
                bundle_id: prefer(\.metadata.bundleID),
                deps: .build {
                    ":\(name)_library"
                },
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.macOS),
                resources: .build {
                    bundleResources(project: kit.project)
                },
                visibility: .public))
    }
}
