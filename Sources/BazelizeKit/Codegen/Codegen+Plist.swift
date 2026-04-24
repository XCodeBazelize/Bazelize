//
//  Target+Plist.swift
//
//
//  Created by Yume on 2022/8/27.
//

import Foundation
import BazelRules
import PathKit
import RuleBuilder
import XCode

extension Target {
    func generateLoadPlistFragment(_ builder: CodeBuilder) {
        let isGeneratePlist = plistContent != nil
        guard isGeneratePlist || isGeneratePlistAuto || isGeneratePlistDefault else {
            return
        }
        builder.load(loadableRule: Rules.Plist.plist_fragment)
    }
}


/// plist_file
extension Target {
    // MARK: Internal

    var plist_file: Starlark.Label? {
        if let _ = plistContent {
            return ":plist_file"
        }
        return nil
    }

    func generatePlistFile(_ builder: CodeBuilder, _: Kit) {
        guard let plist = plistContent else { return }
        builder.call(
            Rules.Plist.Call.plist_fragment(
                name: "plist_file",
                ext: "plist",
                template: Starlark.custom("""
                '''
                \(plist)
                '''
                """),
                visibility: .private
            )
        )
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

    var plist_auto: Starlark.Label? {
        isGeneratePlistAuto ? ":plist_auto" : nil
    }

    func generatePlistAuto(_ builder: CodeBuilder) {
        if isGeneratePlistAuto {
            let plist = prefer(\.plist) ?? []
            builder.call(
                Rules.Plist.Call.plist_fragment(
                    name: "plist_auto",
                    ext: "plist",
                    template: Starlark.custom("""
                    '''
                    \(plist.withNewLine)
                    '''
                    """),
                    visibility: .private
                )
            )
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

    var plist_default: Starlark.Label? {
        isGeneratePlistDefault ? ":plist_default" : nil
    }

    func generatePlistDefault(_ builder: CodeBuilder) {
        if isGeneratePlistDefault {
            let plist = prefer(\.defaultPlist) ?? []
            builder.call(
                Rules.Plist.Call.plist_fragment(
                    name: "plist_default",
                    ext: "plist",
                    template: Starlark.custom("""
                    '''
                    \(plist.withNewLine)
                    '''
                    """),
                    visibility: .private
                )
            )
        }
    }

    // MARK: Private

    private var isGeneratePlistDefault: Bool {
        let plist = prefer(\.defaultPlist) ?? []
        return !plist.isEmpty
    }
}
