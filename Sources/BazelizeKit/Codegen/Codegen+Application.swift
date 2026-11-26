import Util
extension Target {
    // MARK: Internal

    func generateApplicationCode(_ builder: CodeBuilder, _ kit: Kit) throws {
        switch platformSDK {
        case .iOS: buildIOS(builder, kit)
        case .macOS: buildMac(builder, kit)
        case .tvOS: buildTV(builder, kit)
        case .watchOS: buildWatch(builder, kit)
        case .auto:
            /// No SDK of its own: the device families the project targets are what
            /// is left to read the platform from.
            guard let family = prefer(\.platform.deviceFamily), family.contains(.iphone) else {
                throw UnsupportedTarget.applicationPlatform(target: name, sdk: platformSDK?.rawValue)
            }
            buildIOS(builder, kit)
        default:
            throw UnsupportedTarget.applicationPlatform(target: name, sdk: platformSDK?.rawValue)
        }
    }

    func generateCommandLineApplicationCode(_ builder: CodeBuilder, _ kit: Kit) {
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
        let icons = appIconSelection(project: kit.project)
        builder.call(
            Rules.Apple.IOS.Call.ios_application(
                name: name,
                app_icons: icons?.appIcons,
                primary_app_icon: icons?.primaryAppIcon,
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                    linkedFrameworks(project: kit.project)
                },
                entitlements: entitlementsLabel(project: kit.project),
                extensions: embeddedExtensions(project: kit.project),
                frameworks: embeddedFrameworks(project: kit.project),
                families: deviceFamilies,
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                // "launch_storyboard" => ":Base.lproj/LaunchScreen.storyboard"
                minimum_os_version: prefer(\.platform.iOS),
                resources: .build {
                    bundleResources(project: kit.project)
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
        builder.call(
            Rules.Apple.MacOS.Call.macos_application(
                name: name,
                additional_contents: additionalContents(project: kit.project),
                app_icons: appIcons(project: kit.project),
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                },
                entitlements: entitlementsLabel(project: kit.project),
                extensions: embeddedExtensions(project: kit.project),
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
}
