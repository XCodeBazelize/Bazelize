//
//  File.swift
//  Bazelize
//
//  Created by 林煒峻 on 2026/4/30.
//

import Foundation

extension Target {
    // MARK: Internal

    func generateExtension(_ builder: CodeBuilder, _ kit: Kit) {
        switch platformSDK {
        case .iOS: buildIOS(builder, kit)
        case .macOS: buildMac(builder, kit)
        case .tvOS: buildTV(builder, kit)
        case .watchOS: buildWatch(builder, kit, applicationExtension: true)
        default: break
        }
    }

    /// A watchOS 2 app's code: the WatchKit extension its watch app carries.
    func generateWatchKitExtension(_ builder: CodeBuilder, _ kit: Kit) {
        buildWatch(builder, kit, applicationExtension: false)
    }

    /// An extension on watchOS: the WatchKit extension of a watchOS 2 app, or
    /// an app extension — Intents, a widget — a watch app carries.
    private func buildWatch(_ builder: CodeBuilder, _ kit: Kit, applicationExtension: Bool) {
        builder.call(
            Rules.Apple.WatchOS.Call.watchos_extension(
                name: name,
                application_extension: applicationExtension ? true : nil,
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                    linkedFrameworks(project: kit.project)
                },
                extensions: embeddedExtensions(project: kit.project),
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

    /// An iMessage extension: an app extension Messages loads, embedded in an
    /// application's `PlugIns` or carried by an iMessage app.
    func generateIMessageExtension(_ builder: CodeBuilder, _ kit: Kit) {
        builder.call(
            Rules.Apple.IOS.Call.ios_imessage_extension(
                name: name,
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                entitlements: entitlementsLabel(project: kit.project),
                families: deviceFamilies,
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

    /// A sticker pack has no code: its stickers are an asset catalog —
    /// `.xcassets` or `.xcstickers` — that `actool` compiles into the extension.
    func generateStickerPack(_ builder: CodeBuilder, _ kit: Kit) {
        let catalogs = (assets + stickerAssets).map { "\($0)/**" }
        builder.call(
            Rules.Apple.IOS.Call.ios_sticker_pack_extension(
                name: name,
                bundle_id: bundleIdentifier(project: kit.project),
                entitlements: entitlementsLabel(project: kit.project),
                families: deviceFamilies,
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.iOS),
                sticker_assets: catalogs.isEmpty ? nil : Starlark.glob(catalogs),
                strings: .build {
                    if !allStrings.isEmpty {
                        ":Strings"
                    }
                },
                visibility: .public))
    }

    /// An XPC service is its own bundle inside `Contents/XPCServices`, which the
    /// application's copy phase puts it in.
    func generateXPCService(_ builder: CodeBuilder, _ kit: Kit) {
        builder.call(
            Rules.Apple.MacOS.Call.macos_xpc_service(
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

    private func buildMac(_ builder: CodeBuilder, _ kit: Kit) {
        builder.call(
            Rules.Apple.MacOS.Call.macos_extension(
                name: name,
                additional_contents: additionalContents(project: kit.project),
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

    private func buildIOS(_ builder: CodeBuilder, _ kit: Kit) {
        //        families = ["iphone", "ipad"],
        //        provisioning_profile = ":ShareExtension.mobileprovision",  # 若需要簽名
        builder.call(
            Rules.Apple.IOS.Call.ios_extension(
                name: name,
                bundle_id: bundleIdentifier(project: kit.project),
                deps: .build {
                    ":\(name)_library"
                    frameworks
                },
                entitlements: entitlementsLabel(project: kit.project),
                families: deviceFamilies,
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

    private func buildTV(_ builder: CodeBuilder, _ kit: Kit) {
        builder.call(
            Rules.Apple.TVOS.Call.tvos_extension(
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
