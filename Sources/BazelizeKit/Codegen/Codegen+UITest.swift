//
//  UITest.swift
//
//
//  Created by Yume on 2023/1/7.
//

import Foundation
import BazelRules
import RuleBuilder
import XCode

extension Target {
    // MARK: Internal

    func generateUITest(_ builder: CodeBuilder, _ kit: Kit) {
        switch prefer(\.sdk) {
        case .iOS: generateIOSUITest(builder, kit)
        case .macOS: generateMacUITest(builder, kit)
        case .tvOS: generateTVUITest(builder, kit)
        case .watchOS: generateWatchUITest(builder, kit)
        default: break
        }
    }

    // MARK: Private

    private func generateIOSUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.ios_ui_test)
        builder.call(
            Rules.Apple.IOS.Call.ios_ui_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.iOS),
                test_host: prefer(\.testTargetName).map { target in
                    .init("//\(target):\(target)")
                },
                visibility: .public
            )
        )
    }

    private func generateMacUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.macos_ui_test)
        builder.call(
            Rules.Apple.MacOS.Call.macos_ui_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.macOS),
                test_host: prefer(\.testTargetName).map { target in
                    .init("//\(target):\(target)")
                },
                visibility: .public
            )
        )
    }

    private func generateTVUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.tvos_ui_test)
        builder.call(
            Rules.Apple.TVOS.Call.tvos_ui_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.tvOS),
                test_host: prefer(\.testTargetName).map { target in
                    .init("//\(target):\(target)")
                },
                visibility: .public
            )
        )
    }

    private func generateWatchUITest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.watchos_ui_test)
        builder.call(
            Rules.Apple.WatchOS.Call.watchos_ui_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.watchOS),
                test_host: prefer(\.testTargetName).map { target in
                    .init("//\(target):\(target)")
                },
                visibility: .public
            )
        )
    }
}
