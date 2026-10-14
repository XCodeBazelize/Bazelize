import Foundation
import PathKit
import XcodeProj

struct ConfigListLoader: Hashable {
    let native: XCConfigurationList?
    let sourceRoot: Path

    var configs: [String: Xcode.BuildSettings] {
        (native?.buildConfigurations ?? []).map { config in
            (
                config.name,
                .init(
                    name: config.name,
                    setting: resolvedSettings(for: config)))
        }.toDictionary()
    }

    func merge(_ defaultConfig: ConfigListLoader?) -> [String: Xcode.BuildSettings] {
        guard let defaultConfig else {
            return configs
        }

        let defaults = defaultConfig.configs
        return configs.map { name, current in
            (
                name,
                current.merged(with: defaults[name]))
        }.toDictionary()
    }

    static func == (lhs: ConfigListLoader, rhs: ConfigListLoader) -> Bool {
        lhs.native?.uuid == rhs.native?.uuid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(native?.uuid)
    }

    private func resolvedSettings(for config: XCBuildConfiguration) -> [String: String] {
        let fileSettings = resolvedXCConfigSettings(of: config)
        let inlineSettings = config.buildSettings.mapValues(\.value)
        return fileSettings.merging(inlineSettings) { _, current in current }
    }

    /// Where the configuration's base `.xcconfig` is.
    ///
    /// Xcode writes the reference two ways and a configuration uses one of them:
    /// a file reference inside a group, or — when the file lives in a
    /// synchronized folder — that folder's reference plus a path relative to it.
    /// A project built the second way (NetNewsWire) carries `SDKROOT` and its
    /// deployment targets nowhere else, so missing it loses the whole project.
    private func baseConfiguration(of config: XCBuildConfiguration) -> Path? {
        if
            let file = config.baseConfiguration,
            let path = try? file.fullPath(sourceRoot: sourceRoot.string)
        {
            return Path(path)
        }

        guard
            let anchor = config.baseConfigurationAnchor,
            let relative = config.baseConfigurationReferenceRelativePath,
            let root = try? anchor.fullPath(sourceRoot: sourceRoot.string)
        else {
            return nil
        }

        return Path(root) + relative
    }

    private func resolvedXCConfigSettings(of config: XCBuildConfiguration) -> [String: String] {
        guard let path = baseConfiguration(of: config) else { return [:] }

        var visited: Set<String> = [path.string]
        return resolvedXCConfigSettings(at: path, visited: &visited)
    }

    private func resolvedXCConfigSettings(at path: Path, visited: inout Set<String>) -> [String: String] {
        guard let content = try? String(contentsOfFile: path.string) else { return [:] }

        var result: [String: String] = [:]
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("//") else { continue }

            if
                line.hasPrefix("#include"),
                let start = line.firstIndex(of: "\""),
                let end = line[line.index(after: start)...].firstIndex(of: "\"")
            {
                let includePath = String(line[line.index(after: start)..<end])
                let includeFile = path.parent() + includePath
                if visited.insert(includeFile.string).inserted {
                    let included = resolvedXCConfigSettings(at: includeFile, visited: &visited)
                    result.merge(included) { current, _ in current }
                }
                continue
            }

            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = line[..<separator].trimmingCharacters(in: .whitespacesAndNewlines)
            result[key] = Self.value(of: line[line.index(after: separator)...])
        }

        return result
    }

    /// What the assignment is worth once the file's own punctuation is gone.
    ///
    /// `//` starts a comment anywhere in the line, and a trailing `;` is the
    /// `project.pbxproj` habit leaking into an `.xcconfig` — Xcode accepts both
    /// and neither belongs to the value. `SDKROOT = macosx;` read verbatim is a
    /// platform nothing matches.
    private static func value(of assignment: Substring) -> String {
        let uncommented = assignment.range(of: "//").map { assignment[..<$0.lowerBound] } ?? assignment
        var value = uncommented.trimmingCharacters(in: .whitespaces)
        while value.hasSuffix(";") {
            value = String(value.dropLast()).trimmingCharacters(in: .whitespaces)
        }
        return value
    }
}
