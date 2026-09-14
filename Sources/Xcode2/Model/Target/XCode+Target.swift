import Foundation

// MARK: - XCode.Target

extension XCode {
    public struct Target: Encodable {
        public let name: String
        public let productName: String?
        public let productType: String?
        public let preferConfig: String?
        public let configs: [String: BuildSettings]
        public let metadata: TargetMetadata
        public let buildPhases: [BuildPhase]
        public let files: Files
        public let dependencies: Dependencies
    }
}

extension Dictionary where Key == String, Value == XCode.BuildSettings {
    fileprivate var sortedByKey: [(key: Key, value: Value)] {
        sorted { lhs, rhs in
            lhs.key < rhs.key
        }
    }

    func prefer<T>(config: String?, _ keyPath: KeyPath<Value, T>) -> T? {
        let firstValue = sortedByKey.first?.value[keyPath: keyPath]
        guard let config else { return firstValue }
        return self[config]?[keyPath: keyPath] ?? firstValue
    }

    func prefer<T>(config: String?, _ keyPath: KeyPath<Value, T?>) -> T? {
        let firstValue = sortedByKey.first?.value[keyPath: keyPath]
        guard let config else { return firstValue }
        return self[config]?[keyPath: keyPath] ?? firstValue
    }
}

extension XCode.Target {
    public func prefer<T>(_ keyPath: KeyPath<XCode.BuildSettings, T>) -> T? {
        configs.prefer(config: preferConfig, keyPath)
    }

    public func prefer<T>(_ keyPath: KeyPath<XCode.BuildSettings, T?>) -> T? {
        configs.prefer(config: preferConfig, keyPath)
    }

    public var isTest: Bool {
        switch productType {
        case "com.apple.product-type.bundle.unit-test",
             "com.apple.product-type.bundle.ui-testing":
            return true
        default:
            return false
        }
    }

    public var headers: [String] {
        filePaths(files.headers)
    }

    public var hpps: [String] {
        headers.filter { $0.hasSuffix(".hpp") || $0.hasSuffix(".hh") || $0.hasSuffix(".hxx") }
    }

    public var srcs: [String] {
        filePaths(files.sources)
    }

    public var srcs_c: [String] {
        srcs.filter { $0.hasSuffix(".c") }
    }

    public var srcs_objc: [String] {
        srcs.filter { $0.hasSuffix(".m") }
    }

    public var srcs_cpp: [String] {
        srcs.filter { [".cc", ".cp", ".cpp", ".cxx"].contains(where: $0.hasSuffix) }
    }

    public var srcs_objcpp: [String] {
        srcs.filter { $0.hasSuffix(".mm") }
    }

    public var srcs_swift: [String] {
        srcs.filter { $0.hasSuffix(".swift") }
    }

    public var srcs_metal: [String] {
        srcs.filter { $0.hasSuffix(".metal") }
    }

    public var resources: [String] {
        filePaths(files.resources)
    }

    public var xibs: [String] {
        resources.filter { $0.hasSuffix(".xib") }
    }

    public var storyboards: [String] {
        resources.filter { $0.hasSuffix(".storyboard") }
    }

    public var assets: [String] {
        resources.filter { $0.hasSuffix(".xcassets") }
    }

    public var strings: [String] {
        resources.filter { $0.hasSuffix(".strings") }
    }

    public var stringsdict: [String] {
        resources.filter { $0.hasSuffix(".stringsdict") }
    }

    public var allStrings: [String] {
        strings + stringsdict
    }

    public var importFrameworks: [String] {
        files.frameworks.compactMap(\.path)
    }

    public var frameworksSDK: [String] {
        dependencies.sdkFrameworks
    }

    public var dylibsSDK: [String] {
        dependencies.sdkDylibs
    }

    public var weakFrameworksSDK: [String] {
        dependencies.weakSDKFrameworks
    }

    public var selectedSettings: XCode.BuildSettings {
        if let preferConfig, let settings = configs[preferConfig] {
            return settings
        }
        if let debug = configs["Debug"] {
            return debug
        }
        if let first = configs.keys.sorted().first, let settings = configs[first] {
            return settings
        }
        return .init(name: "", setting: [:])
    }

    private func filePath(_ file: XCode.File) -> String? {
        guard let path = file.path?.trimmingCharacters(in: CharacterSet(charactersIn: "/")), !path.isEmpty else {
            return nil
        }
        return "Sources/\(path)"
    }

    private func filePaths(_ files: [XCode.File]) -> [String] {
        files.compactMap(filePath)
    }
}
