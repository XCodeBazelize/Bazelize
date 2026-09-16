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

    /// Headers Xcode copies into the product, i.e. the ones that end up in the
    /// module Swift and dependents import.
    public var exportedHeaders: [String] {
        filePaths(
            files.headers.filter { header in
                header.attributes.contains("Public") || header.attributes.contains("Private")
            })
    }

    /// Headers that stay internal to the target: reachable while compiling its own
    /// sources, never part of the module.
    public var projectHeaders: [String] {
        filePaths(
            files.headers.filter { header in
                !header.attributes.contains("Public") && !header.attributes.contains("Private")
            })
    }

    public var hpps: [String] {
        headers.filter { $0.hasSuffix(".hpp") || $0.hasSuffix(".hh") || $0.hasSuffix(".hxx") }
    }

    public var srcs: [String] {
        filePaths(files.sources)
    }

    public var srcs_c: [String] {
        sources(ofType: "sourcecode.c.c", extensions: [".c"])
    }

    public var srcs_objc: [String] {
        sources(ofType: "sourcecode.c.objc", extensions: [".m"])
    }

    public var srcs_cpp: [String] {
        sources(ofType: "sourcecode.cpp.cpp", extensions: [".cc", ".cp", ".cpp", ".cxx"])
    }

    public var srcs_objcpp: [String] {
        sources(ofType: "sourcecode.cpp.objcpp", extensions: [".mm"])
    }

    public var srcs_swift: [String] {
        sources(ofType: "sourcecode.swift", extensions: [".swift"])
    }

    public var srcs_metal: [String] {
        sources(ofType: "sourcecode.metal", extensions: [".metal"])
    }

    /// Xcode compiles by declared file type, which can disagree with the extension
    /// (`explicitFileType = sourcecode.cpp.objcpp` on a `.m` file is common for
    /// Objective-C code that includes C++).
    private func sources(ofType type: String, extensions: [String]) -> [String] {
        filePaths(
            files.sources.filter { file in
                if let fileType = file.fileType, Self.compiledFileTypes.contains(fileType) {
                    return fileType == type
                }
                guard let path = file.path else { return false }
                return extensions.contains { path.hasSuffix($0) }
            })
    }

    private static let compiledFileTypes: Set<String> = [
        "sourcecode.c.c",
        "sourcecode.c.objc",
        "sourcecode.cpp.cpp",
        "sourcecode.cpp.objcpp",
        "sourcecode.swift",
        "sourcecode.metal",
    ]

    public var resources: [String] {
        var seen = Set<String>()
        return filePaths(files.resources)
            .map(\.resourceWrapperPath)
            .filter { seen.insert($0).inserted }
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

    public var frameworkSearchPathsSDK: [String] {
        dependencies.sdkFrameworkSearchPaths
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

extension String {
    /// Directories Xcode treats as one resource, however they were discovered.
    ///
    /// A synchronized root group lists the files inside an asset catalog rather
    /// than the catalog, and the catalog is what `actool` compiles and what the
    /// rules take as an attribute.
    fileprivate static let resourceWrapperExtensions: Set<String> = [
        "bundle",
        "docc",
        "icon",
        "mlpackage",
        "scnassets",
        "xcassets",
        "xcdatamodeld",
        "xcstickers"
    ]

    /// The path truncated at the wrapper that owns it, or the path itself.
    fileprivate var resourceWrapperPath: String {
        var components: [String] = []

        for component in split(separator: "/").map(String.init) {
            components.append(component)

            let suffix = component.split(separator: ".").last.map(String.init) ?? ""
            if Self.resourceWrapperExtensions.contains(suffix) {
                return components.joined(separator: "/")
            }
        }

        return self
    }
}
