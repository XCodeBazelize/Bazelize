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
        default: break
        }
    }

    private func buildMac(_ builder: CodeBuilder, _ kit: Kit) {
        let project = kit.project
        builder.load(.macos_extension)
        builder.call(
            Rules.Apple.MacOS.Call.macos_extension(
                name: name,
                additional_contents: additionalContents(project: project),
                bundle_id: bundleIdentifier(project: project),
                deps: .build {
                    ":\(name)_library"
                },
                entitlements: entitlementsLabel(project: project),
                frameworks: embeddedFrameworks(project: project),
                infoplists: .build {
                    plistFile(kit)
                    plist_auto
                    plistDefault(kit)
                },
                minimum_os_version: prefer(\.platform.macOS),
                resources: .build {
                    bundleResources(project: project)
                },
                strings: .build {
                    if !allStrings.isEmpty {
                        ":Strings"
                    }
                },
                visibility: .public))
    }
    
    private func buildIOS(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.ios_extension)
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
}
