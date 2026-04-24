//
//  Codegen+SwiftLibrary.swift
//
//
//  Created by Yume on 2022/7/4.
//

import Foundation
import RuleBuilder
import BazelRules
import XCode

extension Target {
    // MARK: Internal

    func generateSwiftLibrary(_ builder: CodeBuilder, _ kit: Kit) {
        let plugin = kit.plugins.compactMap {
            $0[name]
        }.flatMap(\.deps)

        let builtins: [String] = kit.builtinPlugins
            .compactMap(\.target)
            .reduce([]) { origin, next in
                let data = next[name] ?? []
                return origin + data
            }

        builder.load(.swift_library)
        builder.call(
            Rules.Swift.Call.swift_library(
                name: "\(name)_swift",
                module_name: name,
                srcs: .build {
                    srcs_swift
                },
                deps: .build {
                    frameworksLibrary
                    applicationHost
                    plugin
                    builtins
                },
                data: .build {
                    if !assets.isEmpty {
                        ":Assets"
                    }
                    xibs
                    storyboards
                },
                defines: defines,
                testonly: isTest,
                visibility: .private
            )
        )

        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_library",
                actual: .named("\(name)_swift"),
                visibility: .public
            )
        )
    }

    // MARK: Private

    private var defines: Starlark.Value {
        select(\.swiftDefine).map { text -> [String] in
            let flags: [String] = (text ?? "").split(separator: " ").map(String.init)

            var isPreviousDefine = false
            var result: [String] = []
            for flag in flags {
                if flag == "-D" {
                    isPreviousDefine = true
                } else if isPreviousDefine {
                    /// -D ABC
                    result.append(flag)
                    isPreviousDefine = false
                } else if flag.hasPrefix("-D") {
                    /// -DABC
                    result.append(flag.delete(prefix: "-D"))
                }
            }

            return result
        }.starlark
    }

    /// Unittest's dependency from application
    ///
    /// BUNDLE_LOADER
    ///     $(TEST_HOST)
    /// TEST_HOST
    ///     $(BUILT_PRODUCTS_DIR)/Example.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Example
    ///     build/Debug-iphoneos/Example.app//Example
    private var applicationHost: String? {
        guard let host = prefer(\.testHost) else { return nil }
        guard let _ = prefer(\.bundleLoader) else { return nil }
        guard let targetName = host.components(separatedBy: "/").last else { return nil }
        return "//\(targetName):\(targetName)_library"
    }
}
