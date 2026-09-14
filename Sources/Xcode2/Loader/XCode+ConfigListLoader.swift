import Foundation
import PathKit
import XcodeProj

struct ConfigListLoader: Hashable {
    let native: XCConfigurationList?
    let sourceRoot: Path

    var configs: [String: XCode.BuildSettings] {
        (native?.buildConfigurations ?? []).map { config in
            (
                config.name,
                .init(
                    name: config.name,
                    setting: resolvedSettings(for: config)))
        }.toDictionary()
    }

    func merge(_ defaultConfig: ConfigListLoader?) -> [String: XCode.BuildSettings] {
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
        let fileSettings = resolvedXCConfigSettings(for: config.baseConfiguration)
        let inlineSettings = config.buildSettings.mapValues(\.value)
        return fileSettings.merging(inlineSettings) { _, current in current }
    }

    private func resolvedXCConfigSettings(
        for file: PBXFileReference?,
        visited: inout Set<String>)
        -> [String: String]
    {
        guard let file else { return [:] }
        guard let fullPath = try? file.fullPath(sourceRoot: sourceRoot.string) else { return [:] }
        guard visited.insert(fullPath).inserted else { return [:] }
        return resolvedXCConfigSettings(at: Path(fullPath), visited: &visited)
    }

    private func resolvedXCConfigSettings(for file: PBXFileReference?) -> [String: String] {
        var visited: Set<String> = []
        return resolvedXCConfigSettings(for: file, visited: &visited)
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
            let value = line[line.index(after: separator)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            result[key] = value
        }

        return result
    }
}
