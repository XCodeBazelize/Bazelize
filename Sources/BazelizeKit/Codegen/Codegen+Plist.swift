//
//  Target+Plist.swift
//
//
//  Created by Yume on 2022/8/27.
//

import BazelRules
import Foundation
import PathKit
import Starlark

extension Target {
    func generateLoadPlistFragment(_ builder: CodeBuilder, _ kit: Kit) {
        guard
            plistContent(project: kit.project) != nil ||
            isGeneratePlistAuto(project: kit.project) ||
            isGeneratePlistDefault(project: kit.project)
        else {
            return
        }
        builder.load(loadableRule: Rules.Plist.plist_fragment)
    }
}


/// plist_file
extension Target {
    // MARK: Internal

    var plist_file: Starlark.Label? {
        if configs.values.contains(where: { $0.plist.infoPlist != nil }) {
            return ":plist_file"
        }
        return nil
    }

    func generatePlistFile(_ builder: CodeBuilder, _ kit: Kit) {
        guard let plist = plistContent(project: kit.project) else { return }
        builder.call(
            Rules.Plist.Call.plist_fragment(
                name: "plist_file",
                ext: "plist",
                template: Starlark.custom("""
                '''
                \(plist)
                '''
                """),
                visibility: .private))
    }

    // MARK: Private

    private func plistContent(project: Project?) -> String? {
        guard let project else { return nil }
        guard let plistPath = prefer(\.plist.infoPlist) else {
            return nil
        }
        let path = Path(project.workspacePath) + plistPath

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
        configs.values.contains(where: { !$0.generatedPlist.entries.isEmpty }) ? ":plist_auto" : nil
    }

    func generatePlistAuto(_ builder: CodeBuilder, _: Kit) {
        let settings = selectedSettings
        let plist = settings.generatedPlist.entries
        if !plist.isEmpty {
            builder.call(
                Rules.Plist.Call.plist_fragment(
                    name: "plist_auto",
                    ext: "plist",
                    template: Starlark.custom("""
                    '''
                    \(plist.withNewLine)
                    '''
                    """),
                    visibility: .private))
        }
    }

    // MARK: Private

    private func isGeneratePlistAuto(project: Project?) -> Bool {
        guard project != nil else { return false }
        let settings = selectedSettings
        return settings.generatedPlist.enabled && !settings.generatedPlist.entries.isEmpty
    }
}


/// plist_default
///
/// Needed plist properties written in XCode config
extension Target {
    // MARK: Internal

    var plist_default: Starlark.Label? {
        configs.values.contains(where: { !defaultPlistFragments(for: $0).isEmpty }) ? ":plist_default" : nil
    }

    func generatePlistDefault(_ builder: CodeBuilder, _: Kit) {
        let plist = defaultPlistFragments(for: selectedSettings)
        if !plist.isEmpty {
            builder.call(
                Rules.Plist.Call.plist_fragment(
                    name: "plist_default",
                    ext: "plist",
                    template: Starlark.custom("""
                    '''
                    \(plist.withNewLine)
                    '''
                    """),
                    visibility: .private))
        }
    }

    // MARK: Private

    private func isGeneratePlistDefault(project: Project?) -> Bool {
        guard project != nil else { return false }
        return !defaultPlistFragments(for: selectedSettings).isEmpty
    }

    private func defaultPlistFragments(for settings: BuildSettings) -> [String] {
        let defaults = [
            ("CFBundleName", "$(PRODUCT_NAME)"),
            ("CFBundleIdentifier", "$(PRODUCT_BUNDLE_IDENTIFIER)"),
            ("CFBundleVersion", settings.generatedPlist.currentProjectVersion ?? "$(CURRENT_PROJECT_VERSION)"),
            ("CFBundleExecutable", "$(EXECUTABLE_NAME)"),
            ("CFBundlePackageType", "$(PRODUCT_BUNDLE_PACKAGE_TYPE)"),
            ("CFBundleDevelopmentRegion", "$(DEVELOPMENT_LANGUAGE)"),
            ("CFBundleShortVersionString", settings.generatedPlist.marketingVersion ?? "$(MARKETING_VERSION)"),
        ]

        return defaults.map { key, value in
            """
            <key>\(key)</key>
            <string>\(value)</string>
            """
        }
    }
}
