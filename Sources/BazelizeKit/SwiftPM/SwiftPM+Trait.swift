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

    /// The flags, their settings, and the groups a condition asked for.
    ///
    /// They live under `Packages/` because that is the package the generator
    /// owns: the root `BUILD` belongs to the project.
    func buildTraitRules(_ builder: CodeBuilder) {
        let flags = traitFlags
        guard !flags.isEmpty else { return }

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

        guard !traitGroups.isEmpty else { return }

        builder.load(loadableRule: Rules.Selects.selects)
        for group in traitGroups.keys.sorted() {
            builder.call(
                Rules.Selects.Call.config_setting_group(
                    name: group,
                    match_any: (traitGroups[group] ?? []).map { ":\($0)" }))
        }
    }

    /// `--config=<Package>.<Trait>` for every trait, and `-off` for turning one
    /// off that the graph turns on.
    ///
    /// A configuration is how a Bazel workspace is told what to build, so it is
    /// how a trait is asked for too. The file is always written, because a
    /// `.bazelrc` that imports a file that is not there does not load.
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

        for flag in flags {
            let label = "--//\(PluginSwiftPM.packagesDirectory):\(flag.name)"
            lines.append("")
            lines.append("# \(flag.package): \(flag.trait)\(flag.isDefault ? ", on by default" : "")")
            lines.append("build:\(flag.config) \(label)=true")
            lines.append("build:\(flag.config)-off \(label)=false")
        }

        try (output + "traits.bazelrc").write(lines.joined(separator: "\n") + "\n")
    }
}
