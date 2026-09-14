extension Target {
    // MARK: Internal

    func generateApplicationCode(_ builder: CodeBuilder, _ kit: Kit) {
        switch prefer(\.platform.sdk) {
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
        default: break
        }
    }

    func generateCommandLineApplicationCode(_ builder: CodeBuilder, _: Kit) {
        builder.load(.macos_command_line_application)
        builder.call(
            Rules.Apple.MacOS.Call.macos_command_line_application(
                name: name,
                bundle_id: prefer(\.metadata.bundleID),
                deps: .build {
                    ":\(name)_library"
                },
                infoplists: .build {
                    plist_file
                    plist_auto
                    // plist_default
                },
                minimum_os_version: prefer(\.platform.macOS),
                visibility: .public))
    }

    // MARK: Private

    private func buildWatch(_ builder: CodeBuilder, _: Kit) {
        builder.load(.watchos_application)
        builder.call(
            Rules.Apple.WatchOS.Call.watchos_application(
                name: name,
                bundle_id: prefer(\.metadata.bundleID),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                infoplists: .build {
                    plist_file
                    plist_auto
                    plist_default
                },
                minimum_os_version: prefer(\.platform.watchOS),
                resources: .build {
                    resources
                },
                visibility: .public))
    }

    private func buildIOS(_ builder: CodeBuilder, _: Kit) {
        builder.load(.ios_application)
        builder.call(
            Rules.Apple.IOS.Call.ios_application(
                name: name,
                app_icons: appIcons,
                bundle_id: prefer(\.metadata.bundleID),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                families: prefer(\.platform.deviceFamily)?.map(\.code),
                infoplists: .build {
                    plist_file
                    plist_auto
                    plist_default
                },
                // "launch_storyboard" => ":Base.lproj/LaunchScreen.storyboard"
                minimum_os_version: prefer(\.platform.iOS),
                sdk_frameworks: frameworksSDK,
                strings: .build {
                    if !allStrings.isEmpty {
                        ":Strings"
                    }
                },
                visibility: .public))
    }

    private func buildMac(_ builder: CodeBuilder, _: Kit) {
        builder.load(.macos_application)
        builder.call(
            Rules.Apple.MacOS.Call.macos_application(
                name: name,
                app_icons: appIcons,
                bundle_id: prefer(\.metadata.bundleID),
                deps: .build {
                    ":\(name)_library"
                },
                infoplists: .build {
                    plist_file
                    plist_auto
                    plist_default
                },
                minimum_os_version: prefer(\.platform.macOS),
                visibility: .public))
    }

    private func buildTV(_ builder: CodeBuilder, _: Kit) {
        builder.load(.tvos_application)
        builder.call(
            Rules.Apple.TVOS.Call.tvos_application(
                name: name,
                bundle_id: prefer(\.metadata.bundleID),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                infoplists: .build {
                    plist_file
                    plist_auto
                    plist_default
                },
                minimum_os_version: prefer(\.platform.tvOS),
                resources: .build {
                    resources
                },
                visibility: .public))
    }

    private var appIcons: Starlark.Value? {
        guard let iconName = prefer(\.assetCatalog.appIconName) else { return nil }
        let iconGlobs = assets.map { asset in
            "\(asset)/\(iconName).appiconset/**"
        }
        guard !iconGlobs.isEmpty else { return nil }
        return Starlark.glob(iconGlobs)
    }
}
