//
//  Plugin+Imported.swift
//
//
//  Created by Yume on 2023/2/7.
//

import Foundation
import PathKit
import RuleBuilder
import XCode

// TODO: check static imported (xc)framework
final class PluginImported: PluginBuiltin {
    private lazy var _target: [String : [String]]? = kit.project.targets
        .map { target in
            (target.name, target)
        }
        .toDictionary()
        .mapValues { target in
            target.importFrameworks.map { relativePath in
                let name = Path(relativePath).lastComponentWithoutExtension
                let label = "//:\(name)"
                return label
            }
        }

    override var target: [String : [String]]? {
        _target
    }

    override func build(_ builder: CodeBuilder) {
        let imported = kit.project.frameworks.filter { file in
            file.relativePath != nil
        }

        let frameworks = imported.filter { file in
            file.lastKnownFileType == .framework
        }

        let xcframeworks = imported.filter { file in
            file.lastKnownFileType == .xcframework
        }
        framework(builder, frameworks)
        xcframework(builder, xcframeworks)
    }

    private func xcframework(_ builder: CodeBuilder, _ files: [File]) {
        guard !files.isEmpty else { return }
        builder.load(.apple_dynamic_xcframework_import)

        for file in files {
            guard let relativePath = file.relativePath else { continue }
            let name = Path(relativePath).lastComponentWithoutExtension
            builder.add(.apple_dynamic_xcframework_import) {
                "name" => name
                "xcframework_imports" => Starlark.glob([
                    "\(relativePath)/**",
                ])
                StarlarkProperty.Visibility.public
            }
        }
    }

    private func framework(_ builder: CodeBuilder, _ files: [File]) {
        guard !files.isEmpty else { return }
        builder.load(.apple_dynamic_framework_import)

        for file in files {
            guard let relativePath = file.relativePath else { continue }
            let name = Path(relativePath).lastComponentWithoutExtension
            builder.add(.apple_dynamic_framework_import) {
                "name" => name
                "framework_imports" => Starlark.glob([
                    "\(relativePath)/**",
                ])
                StarlarkProperty.Visibility.public
            }
        }
    }
}

