import Util
extension Target {
    // MARK: Internal

    func generateApplicationCode(_ builder: CodeBuilder, _ kit: Kit) {
        switch platformSDK {
        case .iOS: buildIOS(builder, kit)
        case .macOS: buildMac(builder, kit)
        case .tvOS: buildTV(builder, kit)
        case .watchOS: buildWatch(builder, kit)
        case .auto:
            let family = prefer(\.platform.deviceFamily)
            guard let family else {
                return
            }
            if family.contains(.iphone) {
                buildIOS(builder, kit)
            }
        default:
            Log.codeGenerate.warning("""
            Name: \(name, privacy: .public)
            SDK: \(platformSDK?.rawValue ?? "nil", privacy: .public) has no application rule
            """)
        }
    }

    func generateCommandLineApplicationCode(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.macos_command_line_application)
        builder.call(
            Rules.Apple.MacOS.Call.macos_command_line_application(
                name: name,
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                },
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.macOS),
                visibility: .public))
    }

    // MARK: Private

    private func buildWatch(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.watchos_application)
        builder.call(
            Rules.Apple.WatchOS.Call.watchos_application(
                name: name,
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.watchOS),
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

    private func buildIOS(_ builder: CodeBuilder, _ kit: Kit) {
        let project = kit.project
        builder.load(.ios_application)
        builder.call(
            Rules.Apple.IOS.Call.ios_application(
                name: name,
                app_icons: appIcons(project: kit.project),
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                    linkedFrameworks(project: project)
                },
                entitlements: entitlementsLabel(project: project),
                extensions: embeddedExtensions(project: project),
                frameworks: embeddedFrameworks(project: project),
                families: prefer(\.platform.deviceFamily)?.map(\.code),
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                // "launch_storyboard" => ":Base.lproj/LaunchScreen.storyboard"
                minimum_os_version: prefer(\.platform.iOS),
                resources: .build {
                    bundleResources(project: project)
                },
                sdk_frameworks: frameworksSDK,
                strings: .build {
                    if !allStrings.isEmpty {
                        ":Strings"
                    }
                },
                visibility: .public))
    }

    private func buildMac(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.macos_application)
        builder.call(
            Rules.Apple.MacOS.Call.macos_application(
                name: name,
                app_icons: appIcons(project: kit.project),
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                },
                entitlements: entitlementsLabel(project: kit.project),
                frameworks: embeddedFrameworks(project: kit.project),
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

    private func buildTV(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.tvos_application)
        builder.call(
            Rules.Apple.TVOS.Call.tvos_application(
                name: name,
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.tvOS),
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

    /// `app_icons` globs would fail analysis on a catalog without the icon set
    /// (`glob` disallows empty matches), and targets commonly carry several
    /// catalogs — SwiftUI previews add one.
    func appIcons(project: Project?) -> Starlark.Value? {
        guard let project, let iconName = prefer(\.assetCatalog.appIconName) else { return nil }

        let workspace = Path(project.workspacePath)
        let iconGlobs = assets.compactMap { asset -> String? in
            let relative = asset.delete(prefix: "Sources/") ?? asset
            guard (workspace + relative + "\(iconName).appiconset").exists else { return nil }
            return "\(asset)/\(iconName).appiconset/**"
        }

        return iconGlobs.isEmpty ? nil : Starlark.glob(iconGlobs)
    }

}
