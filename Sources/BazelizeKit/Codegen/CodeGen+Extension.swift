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
        default: break
        }
    }
    
    private func buildIOS(_ builder: CodeBuilder, _ kit: Kit) {
        builder.load(.ios_extension)
        //        families = ["iphone", "ipad"],
        //        provisioning_profile = ":ShareExtension.mobileprovision",  # 若需要簽名
        builder.call(
            Rules.Apple.IOS.Call.ios_extension(
                name: name,
                bundle_id: prefer(\.metadata.bundleID),
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
                visibility: .public))
    }
}
