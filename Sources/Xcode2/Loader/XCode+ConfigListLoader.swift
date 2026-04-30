import XcodeProj

struct ConfigListLoader: Hashable {
    let native: XCConfigurationList?

    var configs: [String: XCode.BuildSettings] {
        (native?.buildConfigurations ?? []).map { config in
            (
                config.name,
                .init(config))
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
}
