//
//  UnitTest.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import BazelRules
import RuleBuilder
import XCode

extension Target {
    // MARK: Internal

    func generateUnitTest(_ builder: CodeBuilder, _ kit: Kit) {
        switch prefer(\.sdk) {
        case .iOS: generateIOSUnitTest(builder, kit)
        case .macOS: generateMacUnitTest(builder, kit)
        case .tvOS: generateTVUnitTest(builder, kit)
        case .watchOS: generateWatchUnitTest(builder, kit)
        default: break
        }
    }

    // MARK: Private

    private func generateIOSUnitTest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.ios_unit_test)
        builder.call(
            Rules.Apple.IOS.Call.ios_unit_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.iOS),
                visibility: .public
            )
        )
    }

    private func generateMacUnitTest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.macos_unit_test)
        builder.call(
            Rules.Apple.MacOS.Call.macos_unit_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.macOS),
                visibility: .public
            )
        )
    }

    private func generateTVUnitTest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.tvos_unit_test)
        builder.call(
            Rules.Apple.TVOS.Call.tvos_unit_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.tvOS),
                visibility: .public
            )
        )
    }

    private func generateWatchUnitTest(_ builder: CodeBuilder, _: Kit) {
        builder.load(.watchos_unit_test)
        builder.call(
            Rules.Apple.WatchOS.Call.watchos_unit_test(
                name: name,
                deps: .build {
                    ":\(name)_library"
                },
                minimum_os_version: prefer(\.watchOS),
                visibility: .public
            )
        )
    }
}
