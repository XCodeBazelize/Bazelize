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
import Util

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

    /// Mirrors `generatePlistFile`: the label has to disappear when the file is
    /// missing or unreadable, otherwise the rule references a target nobody emits.
    func plistFile(_ kit: Kit) -> Starlark.Label? {
        plistContent(project: kit.project) == nil ? nil : ":plist_file"
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

    /// Keys the emitted `plist_file` fragment actually defines.
    ///
    /// Read from the fragment rather than the source `Info.plist`, so a key dropped
    /// for being unresolvable still gets its build-setting default.
    func infoPlistKeys(project: Project?) -> Set<String> {
        guard let content = plistContent(project: project) else { return [] }
        guard let regex = try? NSRegularExpression(pattern: #"<key>([^<]+)</key>"#) else { return [] }

        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        return Set(
            matches.compactMap { match in
                Range(match.range(at: 1), in: content).map { String(content[$0]) }
            })
    }

    // MARK: Private

    /// One resolved value out of the target's own `Info.plist`, which outranks the
    /// build setting a default would fall back to.
    func infoPlistString(_ key: String, project: Project?) -> String? {
        guard let nodes = infoPlistNodes(project: project) else { return nil }

        let settings = selectedSettings
        var pendingKey: String?

        for node in nodes {
            guard let element = node as? XMLElement else { continue }

            if element.name == "key" {
                pendingKey = element.stringValue
                continue
            }

            defer { pendingKey = nil }
            guard pendingKey == key, element.name == "string" else { continue }
            return element.stringValue?.resolvingBuildSettingReferences(with: settings)
        }

        return nil
    }

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

        var dropped = appIcons(project: project) == nil ? [] : Self.iconKeys
        /// The version an embedded bundle declares has to give way to its parent's.
        if embeddingBundle(project: project) != nil {
            dropped.formUnion(Self.versionPatterns.keys)
        }
        return entries(nodes, dropping: dropped).withNewLine.escapedForPlistFragment
    }

    /// `macos_application`/`ios_application` derive these from `app_icons`, and
    /// `plisttool` fails the build when a fragment disagrees with what it wrote.
    private static let iconKeys: Set<String> = [
        "CFBundleIconFile",
        "CFBundleIconFiles",
        "CFBundleIconName",
    ]

    /// The plist `dict` is a flat `<key>`/value sequence, so a dropped key takes the
    /// element that follows it with it.
    ///
    /// Entries whose value still references an unresolvable build setting are
    /// dropped as well: `plisttool` fails the build on a variable it cannot
    /// substitute, e.g. Xcode built-ins like `$(SDK_VERSION)`.
    private func entries(_ nodes: [XMLNode], dropping keys: Set<String>) -> [String] {
        let settings = selectedSettings
        var result: [String] = []
        var pendingKey: (name: String, xml: String)?

        for node in nodes {
            guard let element = node as? XMLElement else { continue }
            element.detach()

            let xml = element
                .xmlString(options: [.nodePrettyPrint, .nodePreserveAll])
                .replacingOccurrences(of: "$(PRODUCT_MODULE_NAME)", with: "$(PRODUCT_NAME)")
                .resolvingBuildSettingReferences(with: settings)

            if element.name == "key" {
                pendingKey = (element.stringValue ?? "", xml)
                continue
            }

            guard let key = pendingKey else {
                result.append(xml)
                continue
            }
            pendingKey = nil

            guard !keys.contains(key.name) else { continue }

            if xml.hasUnresolvedBuildSettingReference() {
                Log.codeGenerate.warning("""
                Drop Info.plist key \(key.name, privacy: .public) of \
                \(name, privacy: .public): unresolved build setting reference
                """)
                continue
            }

            if isInvalidVersion(key: key.name, value: element.stringValue ?? "") {
                Log.codeGenerate.warning("""
                Drop Info.plist key \(key.name, privacy: .public) of \
                \(name, privacy: .public): value is not a valid version
                """)
                continue
            }

            result.append(key.xml)
            result.append(xml)
        }

        return result
    }

    /// Xcode ships whatever the `Info.plist` says and lets a release script fill
    /// the real number in later — MacPass writes a literal `UNDEFINED`. rules_apple
    /// validates the format instead, so an unusable value is dropped and the
    /// build-setting default takes over.
    private func isInvalidVersion(key: String, value: String) -> Bool {
        guard let pattern = Self.versionPatterns[key] else { return false }
        guard !value.contains("$(") else { return false }
        return value.range(of: pattern, options: .regularExpression) == nil
    }

    /// What rules_apple accepts for each key, mirroring its `plisttool`.
    private static let versionPatterns: [String: String] = [
        "CFBundleVersion": #"^[0-9]+(\.[0-9]+){0,3}([a-z]+[0-9]{1,3})?$"#,
        "CFBundleShortVersionString": #"^[0-9]+(\.[0-9]+){0,3}$"#,
    ]

    /// A build setting is no better a source than the `Info.plist`: MacPass sets
    /// `CURRENT_PROJECT_VERSION` to `${CURRENT_PROJECT_VERSION}`, which is neither a
    /// version nor something `plist_fragment` can carry.
    private func version(_ value: String?, key: String) -> String? {
        guard let value, !value.isEmpty, !value.contains("$") else { return nil }
        guard let pattern = Self.versionPatterns[key] else { return value }
        return value.range(of: pattern, options: .regularExpression) == nil ? nil : value
    }
}

extension String {
    /// Xcode accepts both `$(SETTING)` and `${SETTING}`.
    static let buildSettingPattern = #"\$[({]([A-Za-z0-9_]+)(?::[A-Za-z0-9_]+)?[)}]"#

    /// Variables `plisttool` substitutes itself; leaving them intact keeps
    /// rules_apple in charge of the bundle identity it also validates.
    static let plistToolVariables: Set<String> = [
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
    func resolvingBuildSettingReferences(
        with settings: BuildSettings,
        reserved: Set<String> = Self.plistToolVariables)
        -> String
    {
        guard let regex = try? NSRegularExpression(pattern: Self.buildSettingPattern) else { return self }

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
            guard !reserved.contains(key), let value = settings[key] else { continue }

            result.replaceSubrange(wholeRange, with: value)
        }

        return result
    }

    /// `plist_fragment` treats `{...}` as a `--define` placeholder, so a brace that
    /// reaches the template fails analysis. Unresolved `${SETTING}` references are
    /// rewritten to the equivalent `$(SETTING)`, which `plisttool` also substitutes.
    fileprivate var escapedForPlistFragment: String {
        guard let regex = try? NSRegularExpression(pattern: #"\$\{([A-Za-z0-9_]+)\}"#) else { return self }

        return regex.stringByReplacingMatches(
            in: self,
            range: NSRange(startIndex..., in: self),
            withTemplate: "\\$($1)")
    }

    /// `$(SETTING)` references left after resolution, excluding the ones
    /// `plisttool` substitutes itself.
    func hasUnresolvedBuildSettingReference(reserved: Set<String> = Self.plistToolVariables) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: Self.buildSettingPattern) else { return false }

        return regex.matches(in: self, range: NSRange(startIndex..., in: self)).contains { match in
            guard let keyRange = Range(match.range(at: 1), in: self) else { return false }
            return !reserved.contains(String(self[keyRange]))
        }
    }
}

/// plist_auto
///
/// plist properties written in XCode config with prefix `INFOPLIST_KEY_`
extension Target {
    // MARK: Internal

    /// `INFOPLIST_KEY_*` settings only reach the bundle when Xcode generates the
    /// `Info.plist`; with a checked-in file they are ignored, and emitting them
    /// anyway makes `plisttool` fail on keys the file already defines.
    var plist_auto: Starlark.Label? {
        hasGeneratedPlistEntries ? ":plist_auto" : nil
    }

    func generatePlistAuto(_ builder: CodeBuilder, _: Kit) {
        guard hasGeneratedPlistEntries else { return }

        builder.call(
            Rules.Plist.Call.plist_fragment(
                name: "plist_auto",
                ext: "plist",
                template: Starlark.custom("""
                '''
                \(selectedSettings.generatedPlist.entries.withNewLine)
                '''
                """),
                visibility: .private))
    }

    // MARK: Private

    private var hasGeneratedPlistEntries: Bool {
        let settings = selectedSettings
        return settings.generatedPlist.enabled && !settings.generatedPlist.entries.isEmpty
    }

    private func isGeneratePlistAuto(project: Project?) -> Bool {
        guard project != nil else { return false }
        return hasGeneratedPlistEntries
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
            project: kit.project,
            skipping: infoPlistKeys(project: kit.project)).isEmpty ? nil : ":plist_default"
    }

    func generatePlistDefault(_ builder: CodeBuilder, _ kit: Kit) {
        let plist = defaultPlistFragments(
            for: selectedSettings,
            project: kit.project,
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
        return !defaultPlistFragments(for: selectedSettings, project: project).isEmpty
    }

    /// `plisttool` substitutes only a handful of variables, so a default whose value
    /// it cannot resolve has to be dropped: `macos_command_line_application` bundles
    /// no executable.
    private var unsupportedDefaultPlistKeys: Set<String> {
        var keys: Set<String> = []
        if productType == "com.apple.product-type.tool" {
            keys.insert("CFBundleExecutable")
        }
        /// `plisttool` substitutes `$(PRODUCT_BUNDLE_IDENTIFIER)` from the rule's
        /// `bundle_id`, which a target without one — iina's command line tools —
        /// never sets.
        if prefer(\.metadata.bundleID) == nil {
            keys.insert("CFBundleIdentifier")
        }
        return keys
    }


    /// The target's own `Info.plist` is the source of truth Xcode uses, so a
    /// default derived from build settings must not restate those keys: `plisttool`
    /// rejects two fragments that disagree on one key.
    private func defaultPlistFragments(
        for settings: BuildSettings,
        project: Project?,
        skipping existing: Set<String> = [])
        -> [String]
    {
        /// rules_apple requires an embedded bundle to carry the version of the bundle
        /// that embeds it — Apple's own rule, which Xcode never enforces.
        let parent = embeddingBundle(project: project)
        let currentVersion = parent.map { bundle in
            bundle.infoPlistString("CFBundleVersion", project: project)
                ?? bundle.prefer(\.generatedPlist.currentProjectVersion)
        } ?? settings.generatedPlist.currentProjectVersion
        let shortVersion = parent.map { bundle in
            bundle.infoPlistString("CFBundleShortVersionString", project: project)
                ?? bundle.prefer(\.generatedPlist.marketingVersion)
        } ?? settings.generatedPlist.marketingVersion

        let defaults = [
            ("CFBundleName", "$(PRODUCT_NAME)"),
            ("CFBundleIdentifier", "$(PRODUCT_BUNDLE_IDENTIFIER)"),
            /// `plisttool` cannot resolve these, and rules_apple rejects a bundle
            /// without them, so an unset setting falls back to Xcode's own template
            /// values instead of a literal `$(SETTING)`.
            ("CFBundleVersion", version(currentVersion, key: "CFBundleVersion") ?? "1"),
            ("CFBundleExecutable", "$(EXECUTABLE_NAME)"),
            ("CFBundleDevelopmentRegion", "$(DEVELOPMENT_LANGUAGE)"),
            (
                "CFBundleShortVersionString",
                version(shortVersion, key: "CFBundleShortVersionString") ?? "1.0"),
        ]

        return defaults
            .filter { key, _ in !existing.contains(key) && !unsupportedDefaultPlistKeys.contains(key) }
            .map { key, value in
                """
                <key>\(key)</key>
                <string>\(value)</string>
                """
            }
    }
}
