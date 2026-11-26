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
                template: Starlark.tripleQuoted(plist),
                visibility: .private))
    }

    /// Keys the emitted `plist_file` fragment actually defines.
    ///
    /// Read from the fragment rather than the source `Info.plist`, so a key dropped
    /// for being unresolvable still gets its build-setting default.
    func infoPlistKeys(project: borrowing Project) -> Set<String> {
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
    func infoPlistString(_ key: PlistKey, project: borrowing Project) -> String? {
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
            guard pendingKey == key.rawValue, element.name == "string" else { continue }
            return element.stringValue?.resolvingBuildSettingReferences(with: settings)
        }

        return nil
    }

    private func infoPlistNodes(project: borrowing Project) -> [XMLNode]? {
        guard let plistPath = prefer(\.plist.infoPlist) else { return nil }

        let path = Path(project.workspacePath) + plistPath
        guard let content: String = try? path.read() else { return nil }

        return try? XMLDocument(xmlString: content, options: .documentXInclude)
            .rootElement()?
            .elements(forName: "dict")
            .first?
            .children
    }

    private func plistContent(project: borrowing Project) -> String? {
        guard let nodes = infoPlistNodes(project: project) else { return nil }

        /// Keys `plisttool` cannot resolve for this product are as unusable in the
        /// target's own `Info.plist` as they are in a default: a command line tool
        /// has no `CFBundleExecutable` to substitute.
        var dropped = unsupportedDefaultPlistKeys
        dropped.formUnion(appIcons(project: project) == nil ? [] : Self.iconKeys)
        /// The version an embedded bundle declares has to give way to its parent's.
        if embeddingBundleIndex(project: project) != nil {
            dropped.formUnion(Self.versionPatterns.keys)
        }
        return entries(nodes, dropping: dropped).withNewLine.escapedForPlistFragment
    }

    /// `macos_application`/`ios_application` derive these from `app_icons`, and
    /// `plisttool` fails the build when a fragment disagrees with what it wrote.
    private static let iconKeys: Set<PlistKey> = [
        .bundleIconFile,
        .bundleIconFiles,
        .bundleIconName,
    ]

    /// The plist `dict` is a flat `<key>`/value sequence, so a dropped key takes the
    /// element that follows it with it.
    ///
    /// Entries whose value still references an unresolvable build setting are
    /// dropped as well: `plisttool` fails the build on a variable it cannot
    /// substitute, e.g. Xcode built-ins like `$(SDK_VERSION)`.
    private func entries(_ nodes: [XMLNode], dropping keys: Set<PlistKey>) -> [String] {
        /// The log message escapes, and a borrowed target cannot go with it.
        let name = name
        let settings = selectedSettings
        var result: [String] = []
        var pendingKey: (name: String, xml: String)?

        for node in nodes {
            guard let element = node as? XMLElement else { continue }
            element.detach()

            let xml = element
                .xmlString(options: [.nodePrettyPrint, .nodePreserveAll])
                .replacingOccurrences(
                    of: BuildSettings.Key.productModuleName.reference,
                    with: BuildSettings.Key.productName.reference)
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

            let plistKey = PlistKey(rawValue: key.name)
            guard !(plistKey.map(keys.contains) ?? false) else { continue }

            if xml.hasUnresolvedBuildSettingReference() {
                Log.codeGenerate.warning("""
                Drop Info.plist key \(key.name, privacy: .public) of \
                \(name, privacy: .public): unresolved build setting reference
                """)
                continue
            }

            if isInvalidVersion(key: plistKey, value: element.stringValue ?? "") {
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
    private func isInvalidVersion(key: PlistKey?, value: String) -> Bool {
        guard let key, let pattern = Self.versionPatterns[key] else { return false }
        guard !value.contains("$(") else { return false }
        return value.range(of: pattern, options: .regularExpression) == nil
    }

    /// What rules_apple accepts for each key, mirroring its `plisttool`.
    private static let versionPatterns: [PlistKey: String] = [
        .bundleVersion: #"^[0-9]+(\.[0-9]+){0,3}([a-z]+[0-9]{1,3})?$"#,
        .bundleShortVersionString: #"^[0-9]+(\.[0-9]+){0,3}$"#,
    ]

    /// A build setting is no better a source than the `Info.plist`: MacPass sets
    /// `CURRENT_PROJECT_VERSION` to `${CURRENT_PROJECT_VERSION}`, which is neither a
    /// version nor something `plist_fragment` can carry.
    private func version(_ value: String?, key: PlistKey) -> String? {
        guard let value, !value.isEmpty, !value.contains("$") else { return nil }
        guard let pattern = Self.versionPatterns[key] else { return value }
        return value.range(of: pattern, options: .regularExpression) == nil ? nil : value
    }
}

extension String {
    /// Xcode accepts both `$(SETTING)` and `${SETTING}`, each with a modifier —
    /// `$(SETTING:default=value)` is the one that carries information.
    static let buildSettingPattern = #"\$[({]([A-Za-z0-9_]+)(?::([^)}]*))?[)}]"#

    /// Variables `plisttool` substitutes itself; leaving them intact keeps
    /// rules_apple in charge of the bundle identity it also validates.
    static let plistToolVariables = Set([
        BuildSettings.Key.bundleName,
        .developmentLanguage,
        .executableName,
        .productBundleIdentifier,
        .productName,
        .targetName,
    ].map(\.rawValue))

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
            guard !reserved.contains(key) else { continue }

            let modifier = Range(match.range(at: 2), in: self).map { String(self[$0]) }
            /// `$(KEY:default=value)` is the only modifier that answers what a
            /// missing setting is; any other one — `:lower`, say — leaves the
            /// reference as it was rather than pasting the modifier in.
            guard let value = settings[key] ?? modifier?.delete(prefix: "default=") else { continue }

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
/// plist properties written in Xcode config with prefix `INFOPLIST_KEY_`
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
                template: Starlark.tripleQuoted(selectedSettings.generatedPlist.entries.withNewLine),
                visibility: .private))
    }

    // MARK: Private

    private var hasGeneratedPlistEntries: Bool {
        let settings = selectedSettings
        return settings.generatedPlist.enabled && !settings.generatedPlist.entries.isEmpty
    }

    private func isGeneratePlistAuto(project _: borrowing Project) -> Bool {
        hasGeneratedPlistEntries
    }
}


/// plist_default
///
/// Needed plist properties written in Xcode config
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
                    template: Starlark.tripleQuoted(plist.withNewLine),
                    visibility: .private))
        }
    }

    // MARK: Private

    private func isGeneratePlistDefault(project: borrowing Project) -> Bool {
        !defaultPlistFragments(for: selectedSettings, project: project).isEmpty
    }

    /// `plisttool` substitutes only a handful of variables, so a default whose value
    /// it cannot resolve has to be dropped: `macos_command_line_application` bundles
    /// no executable.
    var unsupportedDefaultPlistKeys: Set<PlistKey> {
        var keys: Set<PlistKey> = []
        if productType == .commandLineTool {
            keys.insert(.bundleExecutable)
        }
        /// `plisttool` substitutes `$(PRODUCT_BUNDLE_IDENTIFIER)` from the rule's
        /// `bundle_id`, which a target without one — iina's command line tools —
        /// never sets.
        if prefer(\.metadata.bundleID) == nil {
            keys.insert(.bundleIdentifier)
        }
        return keys
    }


    /// The target's own `Info.plist` is the source of truth Xcode uses, so a
    /// default derived from build settings must not restate those keys: `plisttool`
    /// rejects two fragments that disagree on one key.
    private func defaultPlistFragments(
        for settings: BuildSettings,
        project: borrowing Project,
        skipping existing: Set<String> = [])
        -> [String]
    {
        /// rules_apple requires an embedded bundle to carry the version of the bundle
        /// that embeds it — Apple's own rule, which Xcode never enforces.
        let parent = embeddingBundleIndex(project: project)
        let currentVersion = parent.map { index in
            project.targets[index].infoPlistString(.bundleVersion, project: project)
                ?? project.targets[index].prefer(\.generatedPlist.currentProjectVersion)
        } ?? settings.generatedPlist.currentProjectVersion
        let shortVersion = parent.map { index in
            project.targets[index].infoPlistString(.bundleShortVersionString, project: project)
                ?? project.targets[index].prefer(\.generatedPlist.marketingVersion)
        } ?? settings.generatedPlist.marketingVersion

        let defaults: [(PlistKey, String)] = [
            (.bundleName, BuildSettings.Key.productName.reference),
            (.bundleIdentifier, BuildSettings.Key.productBundleIdentifier.reference),
            /// `plisttool` cannot resolve these, and rules_apple rejects a bundle
            /// without them, so an unset setting falls back to Xcode's own template
            /// values instead of a literal `$(SETTING)`.
            (.bundleVersion, version(currentVersion, key: .bundleVersion) ?? "1"),
            (.bundleExecutable, BuildSettings.Key.executableName.reference),
            (.bundleDevelopmentRegion, BuildSettings.Key.developmentLanguage.reference),
            (.bundleShortVersionString, version(shortVersion, key: .bundleShortVersionString) ?? "1.0"),
        ]

        return defaults
            .filter { key, _ in !existing.contains(key.rawValue) && !unsupportedDefaultPlistKeys.contains(key) }
            .map { key, value in
                """
                <key>\(key.rawValue)</key>
                <string>\(value)</string>
                """
            }
    }
}
