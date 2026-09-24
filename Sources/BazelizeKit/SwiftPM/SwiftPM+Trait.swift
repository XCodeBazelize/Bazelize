//
//  SwiftPM+Trait.swift
//
//
//  A package's traits, as something the build decides rather than the
//  generator.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// One trait of one package, as a flag a build can flip.
    struct TraitFlag {
        /// `trait_<Package>_<Trait>`, the flag's name under `//Packages`.
        let name: String
        /// `<Package>.<Trait>`, the name a `--config` goes by.
        let config: String
        let package: String
        let trait: String
        /// The traits selecting this one enables, including itself.
        let selection: Set<String>
        /// What the graph resolves the trait to: a package's default traits, or
        /// what a dependent asked for by name.
        let isDefault: Bool
    }

    /// Every trait every package in the workspace declares.
    ///
    /// The flag defaults to what the manifest graph says, so a build that asks
    /// for nothing is the build SwiftPM would have made; `--config=<Package>.<Trait>`
    /// is how a build asks for something else.
    var traitFlags: [TraitFlag] {
        workspace.packages.flatMap { package -> [TraitFlag] in
            let enabled = workspace.traits[package.identity] ?? []
            let traits = Dictionary(
                package.manifest.traits.map { ($0.name, $0) },
                uniquingKeysWith: { first, _ in first })

            func selection(of name: String) -> Set<String> {
                var selected: Set<String> = []
                var pending = [name]
                while let next = pending.popLast() {
                    guard selected.insert(next).inserted else { continue }
                    pending += traits[next]?.enabledTraits ?? []
                }
                selected.remove("default")
                return selected
            }

            return package.manifest.traits
                /// Not a trait: the list of traits a build that says nothing gets.
                .filter { $0.name != "default" }
                .sorted { $0.name < $1.name }
                .map { trait in
                    TraitFlag(
                        name: Self.flagName(package: package.directory, trait: trait.name),
                        config: "\(package.directory).\(trait.name)",
                        package: package.directory,
                        trait: trait.name,
                        selection: selection(of: trait.name),
                        isDefault: enabled.contains(trait.name))
                }
        }
    }

    static func flagName(package: String, trait: String) -> String {
        "trait_\(identifier(package))_\(identifier(trait))"
    }

    /// A label is not a place for whatever a package is called on disk.
    private static func identifier(_ name: String) -> String {
        String(name.map { character in
            character.isLetter || character.isNumber || character == "_" ? character : "_"
        })
    }

    /// The label a `select` keys a trait condition on, or `nil` when what
    /// carries the condition is in every build.
    ///
    /// A condition naming several traits is satisfied by any of them, which is
    /// a `config_setting_group`; the group is recorded here and written with
    /// the flags.
    func traitCondition(_ traits: [String], in package: SwiftPM.Package) -> String? {
        let names = traits.sorted()
        guard let first = names.first else { return nil }

        let settings = names.map { "\(Self.flagName(package: package.directory, trait: $0))_on" }
        guard names.count > 1 else {
            return "//\(PluginSwiftPM.packagesDirectory):\(settings[0])"
        }

        let group = "\(Self.flagName(package: package.directory, trait: first))_or_\(names.count - 1)_more"
        traitGroups[group] = settings
        return "//\(PluginSwiftPM.packagesDirectory):\(group)"
    }

    /// The label a setting condition selects on. Trait names are alternatives
    /// within the trait condition; a build configuration must also match when
    /// the manifest names both.
    func settingCondition(
        _ condition: SwiftPM.SettingCondition?,
        in package: SwiftPM.Package) -> String?
    {
        guard let condition else { return nil }

        let trait = traitCondition(condition.traits, in: package)
        let configuration = configurationCondition(condition.config)
        switch (trait, configuration) {
        case (nil, nil):
            return nil
        case (.some(let label), nil), (nil, .some(let label)):
            return label
        case (.some(let trait), .some(let configuration)):
            let names = condition.traits.sorted() + [condition.config?.lowercased() ?? ""]
            let group = "condition_\(Self.identifier(package.directory))_"
                + names.map(Self.identifier).joined(separator: "_and_")
            conditionGroups[group] = [trait, configuration]
            return "//\(PluginSwiftPM.packagesDirectory):\(group)"
        }
    }

    private func configurationCondition(_ configuration: String?) -> String? {
        guard let configuration = configuration?.lowercased(),
              configuration == "debug" || configuration == "release"
        else {
            return nil
        }

        configurationConditions.insert(configuration)
        return "//\(PluginSwiftPM.packagesDirectory):swiftpm_\(configuration)"
    }

    /// A list of flags or labels, plus one `select` per trait condition.
    ///
    /// One `select` each rather than one with several keys: two traits can be
    /// on at once, and a `select` whose keys both match is an error rather than
    /// both lists.
    func traitValue(
        _ always: [String],
        conditional: [(condition: String, values: [String])]) -> Starlark.Value?
    {
        guard !conditional.isEmpty else { return always.starlark }

        let parts = [Starlark.Value.array(always.map { .label(.init($0)) }).text]
            + conditional.map { entry in
                """
                select({
                    "\(entry.condition)": \(Starlark.Value.array(entry.values.map { .label(.init($0)) }).text),
                    "//conditions:default": [],
                })
                """
            }

        return .custom(parts.joined(separator: " + "))
    }

    /// The flags, configuration settings, and groups a condition asked for.
    ///
    /// They live under `Packages/` because that is the package the generator
    /// owns: the root `BUILD` belongs to the project.
    func buildTraitRules(_ builder: CodeBuilder) {
        let flags = traitFlags
        if !flags.isEmpty {
            builder.load(.bool_flag)
            for flag in flags {
                builder.call(
                    Rules.Config.Call.bool_flag(
                        name: flag.name,
                        build_setting_default: flag.isDefault,
                        visibility: .public))
                builder.call(
                    Rules.Builtin.Call.config_setting(
                        name: "\(flag.name)_on",
                        flag_values: [":\(flag.name)": "true"]))
            }
        }

        if configurationConditions.contains("debug") {
            builder.call(
                Rules.Builtin.Call.config_setting(
                    name: "swiftpm_debug_dbg",
                    values: ["compilation_mode": "dbg"]))
            builder.call(
                Rules.Builtin.Call.config_setting(
                    name: "swiftpm_debug_fastbuild",
                    values: ["compilation_mode": "fastbuild"]))
        }
        if configurationConditions.contains("release") {
            builder.call(
                Rules.Builtin.Call.config_setting(
                    name: "swiftpm_release",
                    values: ["compilation_mode": "opt"]))
        }

        let hasGroups = !traitGroups.isEmpty
            || !conditionGroups.isEmpty
            || configurationConditions.contains("debug")
        guard hasGroups else { return }

        builder.load(loadableRule: Rules.Selects.selects)
        if configurationConditions.contains("debug") {
            builder.call(
                Rules.Selects.Call.config_setting_group(
                    name: "swiftpm_debug",
                    match_any: [":swiftpm_debug_dbg", ":swiftpm_debug_fastbuild"]))
        }
        for group in traitGroups.keys.sorted() {
            builder.call(
                Rules.Selects.Call.config_setting_group(
                    name: group,
                    match_any: (traitGroups[group] ?? []).map { ":\($0)" }))
        }
        for group in conditionGroups.keys.sorted() {
            builder.call(
                Rules.Selects.Call.config_setting_group(
                    name: group,
                    match_all: conditionGroups[group] ?? []))
        }
    }

    /// `--config=<Package>.<Trait>` for every trait a package declares.
    ///
    /// SwiftPM treats an explicit trait selection as a replacement for that
    /// package's defaults. Each configuration therefore writes every flag for
    /// the package, turning on only the selected trait and its transitive
    /// `enabledTraits`. Multiple selections remain available through the
    /// underlying boolean flags.
    ///
    /// The file is always written, because a `.bazelrc` that imports a file
    /// that is not there does not load.
    func writeTraitConfigs() throws {
        let flags = traitFlags
        var lines = [
            "# Generated by Bazelize: one --config per trait of the packages this",
            "# workspace builds. A trait's flag defaults to what the manifests say,",
            "# so a build that asks for nothing is the build SwiftPM would make.",
        ]

        if flags.isEmpty {
            lines.append("#")
            lines.append("# No package in this workspace declares a trait.")
        }

        for selected in flags {
            lines.append("")
            lines.append("# \(selected.package): \(selected.trait)\(selected.isDefault ? ", on by default" : "")")
            for flag in flags where flag.package == selected.package {
                lines.append(
                    "build:\(selected.config) --//\(PluginSwiftPM.packagesDirectory):\(flag.name)="
                        + (selected.selection.contains(flag.trait) ? "true" : "false"))
            }
        }

        try (output + "traits.bazelrc").write(lines.joined(separator: "\n") + "\n")
    }
}
