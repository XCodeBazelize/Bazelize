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

    /// SwiftPM platform names that have the same meaning in Bazel's standard
    /// OS constraint. A custom platform has no constraint to select on; it is
    /// represented by a condition no generated target platform carries.
    private static let standardPlatformConstraints: Set = [
        "android", "chromiumos", "emscripten", "freebsd", "fuchsia", "haiku",
        "ios", "linux", "macos", "netbsd", "nixos", "none", "openbsd", "qnx",
        "tvos", "uefi", "visionos", "vxworks", "wasi", "watchos", "windows",
    ]

    private static let unsupportedPlatformCondition =
        "//\(PluginSwiftPM.packagesDirectory):swiftpm_unsupported_platform"

    /// The label a `select` keys a platform condition on. Several platforms
    /// are alternatives, exactly as they are in `PackageDescription`.
    func platformCondition(_ platforms: [String]) -> String? {
        let names = Set(platforms.map { $0.lowercased() }).sorted()
        guard !names.isEmpty else { return nil }

        let labels = Set(names.map { name -> String in
            /// Catalyst is iOS APIs in the Catalyst target environment, not a
            /// separate standard OS constraint.
            if name == "maccatalyst" {
                let group = "swiftpm_platform_maccatalyst"
                conditionGroups[group] = [
                    "@platforms//os:ios",
                    "@apple_support//constraints:catalyst",
                ]
                return "//\(PluginSwiftPM.packagesDirectory):\(group)"
            }

            guard Self.standardPlatformConstraints.contains(name) else {
                if unsupportedPlatforms.insert(name).inserted {
                    note("""
                    SwiftPM platform condition '\(name)' has no matching Bazel platform \
                    constraint: values behind it stay out of the build.
                    """)
                }
                return Self.unsupportedPlatformCondition
            }
            return "@platforms//os:\(name)"
        }).sorted()

        guard labels.count > 1 else { return labels[0] }
        let group = "swiftpm_platform_" + names.map(Self.identifier).joined(separator: "_or_")
        platformGroups[group] = labels
        return "//\(PluginSwiftPM.packagesDirectory):\(group)"
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

    /// The label a setting or dependency condition selects on. Platforms and
    /// traits are alternatives within their own dimension; dimensions and the
    /// build configuration all have to match together.
    func settingCondition(
        _ condition: SwiftPM.SettingCondition?,
        in package: SwiftPM.Package)
        -> String?
    {
        guard let condition else { return nil }

        let members = [
            platformCondition(condition.platformNames),
            traitCondition(condition.traits, in: package),
            configurationCondition(condition.config),
        ].compactMap { $0 }

        guard let first = members.first else { return nil }
        guard members.count > 1 else { return first }

        let dimensions = condition.platformNames.sorted().map { "platform_\(Self.identifier($0))" }
            + condition.traits.sorted().map { "trait_\(Self.identifier($0))" }
            + (condition.config.map { ["configuration_\(Self.identifier($0.lowercased()))"] } ?? [])
        let group = "condition_\(Self.identifier(package.directory))_"
            + dimensions.joined(separator: "_and_")
        conditionGroups[group] = members
        return "//\(PluginSwiftPM.packagesDirectory):\(group)"
    }

    private func configurationCondition(_ configuration: String?) -> String? {
        guard
            let configuration = configuration?.lowercased(),
            configuration == "debug" || configuration == "release"
        else {
            return nil
        }

        configurationConditions.insert(configuration)
        return "//\(PluginSwiftPM.packagesDirectory):swiftpm_\(configuration)"
    }

    /// A list of flags or labels, plus one `select` per build condition.
    ///
    /// One `select` each rather than one with every key: two conditions can be
    /// on at once, and a `select` whose keys both match is an error rather than
    /// both lists.
    func conditionalValue(
        _ always: [String],
        conditional: [(condition: String, values: [String])])
        -> Starlark.Value?
    {
        guard !conditional.isEmpty else { return always.starlark }

        let selects = conditional.map { entry in
            Starlark.Value.select(
                .conditional(
                    [.named(entry.condition): .array(entry.values.map(Starlark.Value.string))],
                    fallback: .array([])))
        }

        return .concat([.array(always.map(Starlark.Value.string))] + selects)
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

        if !unsupportedPlatforms.isEmpty {
            builder.call(
                Rules.Builtin.Call.constraint_setting(
                    name: "swiftpm_unsupported_platform_setting"))
            builder.call(
                Rules.Builtin.Call.constraint_value(
                    name: "swiftpm_unsupported_platform",
                    constraint_setting: ":swiftpm_unsupported_platform_setting",
                    visibility: .public))
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
            || !platformGroups.isEmpty
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
        for group in platformGroups.keys.sorted() {
            builder.call(
                Rules.Selects.Call.config_setting_group(
                    name: group,
                    match_any: platformGroups[group] ?? []))
        }
        for group in conditionGroups.keys.sorted() {
            builder.call(
                Rules.Selects.Call.config_setting_group(
                    name: group,
                    match_all: conditionGroups[group] ?? []))
        }
    }

    /// `--config=<Package>.<Trait>` for every trait a package declares, and the
    /// three selections SwiftPM names rather than lists.
    ///
    /// SwiftPM treats an explicit trait selection as a replacement for that
    /// package's defaults. Each configuration therefore writes every flag for
    /// the package, turning on only what the selection covers — a trait and its
    /// transitive `enabledTraits`, everything for `--enable-all-traits`,
    /// nothing for `--disable-default-traits`.
    ///
    ///     swift build                          # nothing to pass
    ///     --disable-default-traits             --config=<Package>.none
    ///     --enable-all-traits                  --config=<Package>.all
    ///     --traits default                     --config=<Package>.default
    ///     --traits Leaf                        --config=<Package>.Leaf
    ///
    /// `--traits Leaf,Alternative` selects several at once, which one
    /// configuration cannot be: the flags are public, so a build that wants a
    /// combination sets them.
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

        /// The selections SwiftPM has a name for rather than a list.
        var packages: [String] = []
        for flag in flags where !packages.contains(flag.package) {
            packages.append(flag.package)
        }

        for package in packages {
            let owned = flags.filter { $0.package == package }

            for named in NamedSelection.allCases {
                lines.append("")
                lines.append("# \(package): \(named.comment)")
                for flag in owned {
                    lines.append(
                        "build:\(package).\(named.rawValue) --//\(PluginSwiftPM.packagesDirectory):\(flag.name)="
                            + (named.covers(flag) ? "true" : "false"))
                }
            }
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

    /// `--disable-default-traits`, `--enable-all-traits` and `--traits default`,
    /// which name a selection instead of listing it.
    enum NamedSelection: String, CaseIterable {
        case none
        case all
        case `default`

        var comment: String {
            switch self {
            case .none:
                return "no trait at all, which is `--disable-default-traits`"
            case .all:
                return "every trait, which is `--enable-all-traits`"
            case .default:
                return "the traits a build that asks for nothing gets"
            }
        }

        func covers(_ flag: TraitFlag) -> Bool {
            switch self {
            case .none:
                return false
            case .all:
                return true
            case .default:
                return flag.isDefault
            }
        }
    }
}
