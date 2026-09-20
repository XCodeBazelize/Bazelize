import Foundation
import PathKit
import Starlark
import Util
import Xcode

extension Target {
    /// The entitlements Xcode signs with, rewritten into the generated tree.
    ///
    /// The source file is written for Xcode, which expands build settings and the
    /// team prefix while signing; rules_apple substitutes neither, and its
    /// `plisttool` fails the build on a variable it does not know.
    /// Variables rules_apple's `plisttool` substitutes into entitlements itself.
    fileprivate static let entitlementVariables: Set<String> = ["CFBundleIdentifier"]

    var entitlementsPath: String? {
        guard let entitlements = metadata.entitlements, !entitlements.isEmpty else { return nil }
        return "Generated/\(Path(entitlements).lastComponent)"
    }

    func entitlementsLabel(project: Project?) -> Starlark.Label? {
        entitlementsContent(project: project) == nil ? nil : .named(entitlementsPath ?? "")
    }

    /// `nil` when the target declares no entitlements, or when the file is missing:
    /// the rule attribute has to disappear with it.
    func entitlementsContent(project: Project?) -> String? {
        guard let project, let entitlements = metadata.entitlements, !entitlements.isEmpty else { return nil }

        let path = Path(project.workspacePath) + entitlements
        guard
            let content: String = try? path.read(),
            let document = try? XMLDocument(xmlString: content, options: .documentXInclude),
            let root = document.rootElement(),
            let dict = root.elements(forName: "dict").first
        else {
            return nil
        }

        let entries = resolvedEntitlementEntries(dict.children ?? [])
        dict.setChildren(nil)
        for entry in entries {
            dict.addChild(entry)
        }

        return document.xmlString(options: [.nodePrettyPrint, .nodePreserveAll]) + "\n"
    }

    // MARK: Private

    /// The `dict` is a flat `<key>`/value sequence, so a dropped key takes the
    /// element that follows it with it.
    private func resolvedEntitlementEntries(_ nodes: [XMLNode]) -> [XMLElement] {
        let settings = selectedSettings
        var result: [XMLElement] = []
        var pendingKey: XMLElement?

        for node in nodes {
            guard let element = node as? XMLElement else { continue }
            element.detach()
            element.resolveEntitlementVariables(with: settings, teamPrefix: teamPrefix)

            if element.name == "key" {
                pendingKey = element
                continue
            }

            guard let key = pendingKey else {
                result.append(element)
                continue
            }
            pendingKey = nil

            let xml = element.xmlString(options: [.nodePreserveAll])
            if xml.hasUnresolvedBuildSettingReference(reserved: Self.entitlementVariables) {
                Log.codeGenerate.warning("""
                Drop entitlement \(key.stringValue ?? "", privacy: .public) of \
                \(name, privacy: .public): unresolved build setting reference
                """)
                continue
            }

            result.append(key)
            result.append(element)
        }

        return result
    }

    /// What Xcode expands `$(AppIdentifierPrefix)` to: the team that signs the
    /// bundle, followed by a dot. rules_apple reads it off a provisioning profile,
    /// which a generated workspace has none of.
    private var teamPrefix: String? {
        guard let team = prefer(\.metadata.developmentTeam), !team.isEmpty else { return nil }
        return "\(team)."
    }
}

extension XMLElement {
    fileprivate func resolveEntitlementVariables(with settings: BuildSettings, teamPrefix: String?) {
        let elements = (children ?? []).compactMap { $0 as? XMLElement }

        // Setting `stringValue` replaces the children, so only a leaf is rewritten:
        // an `<array>` or a nested `<dict>` recurses instead.
        if elements.isEmpty {
            if let value = stringValue {
                stringValue = value
                    .replacingOccurrences(of: "$(AppIdentifierPrefix)", with: teamPrefix ?? "$(AppIdentifierPrefix)")
                    .resolvingBuildSettingReferences(with: settings, reserved: Target.entitlementVariables)
            }
            return
        }

        for element in elements {
            element.resolveEntitlementVariables(with: settings, teamPrefix: teamPrefix)
        }
    }
}
