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

    /// Keys the target's checked-in `Info.plist` already defines.
    func infoPlistKeys(project: Project?) -> Set<String> {
        guard let nodes = infoPlistNodes(project: project) else { return [] }

        return Set(
            nodes
                .compactMap { $0 as? XMLElement }
                .filter { $0.name == "key" }
                .compactMap(\.stringValue))
    }

    // MARK: Private

    private func infoPlistNodes(project: Project?) -> [XMLNode]? {
        guard let project else { return nil }
        guard let plistPath = prefer(\.plist.infoPlist) else { return nil }

        let path = Path(project.workspacePath) + plistPath
        guard let content: String = try? path.read() else { return nil }

        return try? XMLDocument(xmlString: content, options: .documentXInclude)
            .rootElement()?
            .elements(forName: "dict")
            .first?
            .children
    }

    private func plistContent(project: Project?) -> String? {
        guard let nodes = infoPlistNodes(project: project) else { return nil }

        return Self.entries(nodes, dropping: appIcons == nil ? [] : Self.iconKeys)
            .withNewLine
            .replacingOccurrences(of: "$(PRODUCT_MODULE_NAME)", with: "$(PRODUCT_NAME)")
            .resolvingBuildSettingReferences(with: selectedSettings)
    }

    /// `macos_application`/`ios_application` derive these from `app_icons`, and
    /// `plisttool` fails the build when a fragment disagrees with what it wrote.
    private static let iconKeys: Set<String> = [
        "CFBundleIconFile",
        "CFBundleIconFiles",
        "CFBundleIconName",
    ]

    /// The plist `dict` is a flat `<key>`/value sequence, so dropping a key means
    /// dropping the element that follows it too.
    private static func entries(_ nodes: [XMLNode], dropping keys: Set<String>) -> [String] {
        var result: [String] = []
        var skipValue = false

        for node in nodes {
            guard let element = node as? XMLElement else { continue }

            if skipValue {
                skipValue = false
                continue
            }

            if
                element.name == "key",
                let key = element.stringValue,
                keys.contains(key)
            {
                skipValue = true
                continue
            }

            element.detach()
            result.append(element.xmlString(options: [.nodePrettyPrint, .nodePreserveAll]))
        }

        return result
    }
}

extension String {
    /// Variables `plisttool` substitutes itself; leaving them intact keeps
    /// rules_apple in charge of the bundle identity it also validates.
    fileprivate static let plistToolVariables: Set<String> = [
        "BUNDLE_NAME",
        "DEVELOPMENT_LANGUAGE",
        "EXECUTABLE_NAME",
        "PRODUCT_BUNDLE_IDENTIFIER",
        "PRODUCT_NAME",
        "TARGET_NAME",
    ]

    /// Expands the remaining `$(SETTING)` references from the target's build
    /// settings. `plisttool` only knows a handful of variables, so anything else
    /// copied out of an Xcode `Info.plist` would either reach the bundle verbatim
    /// or collide with a resolved value in another fragment.
    fileprivate func resolvingBuildSettingReferences(with settings: BuildSettings) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\$\(([A-Za-z0-9_]+)\)"#) else { return self }

        let matches = regex.matches(in: self, range: NSRange(startIndex..., in: self))
        var result = self

        for match in matches.reversed() {
            guard
                let wholeRange = Range(match.range(at: 0), in: self),
                let keyRange = Range(match.range(at: 1), in: self)
            else {
                continue
            }

            let key = String(self[keyRange])
            guard !Self.plistToolVariables.contains(key), let value = settings[key] else { continue }

            result.replaceSubrange(wholeRange, with: value)
        }

        return result
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

    func plistDefault(_ kit: Kit) -> Starlark.Label? {
        defaultPlistFragments(
            for: selectedSettings,
            skipping: infoPlistKeys(project: kit.project)).isEmpty ? nil : ":plist_default"
    }

    func generatePlistDefault(_ builder: CodeBuilder, _ kit: Kit) {
        let plist = defaultPlistFragments(
            for: selectedSettings,
            skipping: infoPlistKeys(project: kit.project))
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

    /// The target's own `Info.plist` is the source of truth Xcode uses, so a
    /// default derived from build settings must not restate those keys: `plisttool`
    /// rejects two fragments that disagree on one key.
    private func defaultPlistFragments(
        for settings: BuildSettings,
        skipping existing: Set<String> = [])
        -> [String]
    {
        let defaults = [
            ("CFBundleName", "$(PRODUCT_NAME)"),
            ("CFBundleIdentifier", "$(PRODUCT_BUNDLE_IDENTIFIER)"),
            ("CFBundleVersion", settings.generatedPlist.currentProjectVersion ?? "$(CURRENT_PROJECT_VERSION)"),
            ("CFBundleExecutable", "$(EXECUTABLE_NAME)"),
            ("CFBundlePackageType", "$(PRODUCT_BUNDLE_PACKAGE_TYPE)"),
            ("CFBundleDevelopmentRegion", "$(DEVELOPMENT_LANGUAGE)"),
            ("CFBundleShortVersionString", settings.generatedPlist.marketingVersion ?? "$(MARKETING_VERSION)"),
        ]

        return defaults
            .filter { key, _ in !existing.contains(key) }
            .map { key, value in
                """
                <key>\(key)</key>
                <string>\(value)</string>
                """
            }
    }
}
