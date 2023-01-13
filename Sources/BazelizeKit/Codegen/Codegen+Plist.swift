//
//  Target+Plist.swift
//
//
//  Created by Yume on 2022/8/27.
//

import Foundation
import PathKit
import RuleBuilder
import XCode

extension Target {
    func generateLoadPlistFragment(_ builder: inout Build.Builder) {
        let isGeneratePlist = plistContent != nil
        guard isGeneratePlist || isGeneratePlistAuto || isGeneratePlistDefault else {
            return
        }
        builder.load(loadableRule: RulesPlist.plist_fragment)
    }
}


/// plist_file
extension Target {
    // MARK: Internal

    var plist_file: String? {
        if let _ = plistContent {
            return ":plist_file"
        }
        return nil
    }

    func generatePlistFile(_ builder: inout Build.Builder, _: Kit) {
        guard let plist = plistContent else { return }
        builder.add(RulesPlist.plist_fragment.rawValue) {
            "name" => "plist_file"
            "extension" => "plist"
            "template" => Starlark.custom("""
            '''
            \(plist)
            '''
            """)
            StarlarkProperty.Visibility.private
        }
    }

    // MARK: Private

    private var plistContent: String? {
        guard let plistPath = prefer(\.infoPlist) else {
            return nil
        }
        let path: Path = project.workspacePath + plistPath

        guard let content: String = try? path.read() else { return nil }
        guard
            let xml = try? XMLDocument(xmlString: content, options: .documentXInclude)
                .rootElement()?
                .elements(forName: "dict")
                .first?
                .children else { return nil }


        return xml.compactMap { node -> String in
            node.detach()
            return node.xmlString(options: [.nodePrettyPrint, .nodePreserveAll])
        }
        .withNewLine
        .replacingOccurrences(of: "$(PRODUCT_MODULE_NAME)", with: "$(PRODUCT_NAME)")
    }
}

/// plist_auto
///
/// plist properties written in XCode config with prefix `INFOPLIST_KEY_`
extension Target {
    // MARK: Internal

    var plist_auto: String? {
        isGeneratePlistAuto ? ":plist_auto" : nil
    }

    func generatePlistAuto(_ builder: inout Build.Builder) {
        if isGeneratePlistAuto {
            let plist = prefer(\.plist) ?? []
            builder.add(RulesPlist.plist_fragment.rawValue) {
                "name" => "plist_auto"
                "extension" => "plist"
                "template" => Starlark.custom("""
                '''
                \(plist.withNewLine)
                '''
                """)
                StarlarkProperty.Visibility.private
            }
        }
    }

    // MARK: Private

    private var isGeneratePlistAuto: Bool {
        let isAutoGen = prefer(\.generateInfoPlist) ?? false
        let isEmptyPlist = (prefer(\.plist) ?? []).isEmpty
        return isAutoGen && !isEmptyPlist
    }
}


/// plist_default
///
/// Needed plist properties written in XCode config
extension Target {
    // MARK: Internal

    var plist_default: String? {
        isGeneratePlistDefault ? ":plist_default" : nil
    }

    func generatePlistDefault(_ builder: inout Build.Builder) {
        if isGeneratePlistDefault {
            let plist = prefer(\.defaultPlist) ?? []
            builder.add(RulesPlist.plist_fragment.rawValue) {
                "name" => "plist_default"
                "extension" => "plist"
                "template" => Starlark.custom("""
                '''
                \(plist.withNewLine)
                '''
                """)
                StarlarkProperty.Visibility.private
            }
        }
    }

    // MARK: Private

    private var isGeneratePlistDefault: Bool {
        let plist = prefer(\.defaultPlist) ?? []
        return !plist.isEmpty
    }
}
