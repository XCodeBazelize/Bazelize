import Foundation

// MARK: - Xcode.Target

extension Xcode {
    /// A native target as loaded from the project.
    ///
    /// A target has exactly one owner: the `Project` that loaded it. Everything
    /// else borrows it, so the configurations, file lists, and dependencies it
    /// carries are never duplicated after loading.
    public struct Target: ~Copyable {
        public let name: String
        public let productName: String?
        public let productType: ProductType?
        public let preferConfig: String?
        public let configs: [String: BuildSettings]
        public let metadata: TargetMetadata
        public let buildPhases: [BuildPhase]
        public let files: Files
        public let dependencies: Dependencies
    }
}

extension Xcode.Target {
    enum CodingKeys: String, CodingKey {
        case name
        case productName
        case productType
        case preferConfig
        case configs
        case metadata
        case buildPhases
        case files
        case dependencies
    }

    /// Encodes the fields `Encodable` synthesis encoded before the target became
    /// noncopyable, which `Encodable` cannot describe.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encodeIfPresent(productType?.rawValue, forKey: .productType)
        try container.encodeIfPresent(preferConfig, forKey: .preferConfig)
        try container.encode(configs, forKey: .configs)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(buildPhases, forKey: .buildPhases)
        try container.encode(files, forKey: .files)
        try container.encode(dependencies, forKey: .dependencies)
    }
}

extension Dictionary where Key == String, Value == Xcode.BuildSettings {
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

extension Xcode.Target {
    public func prefer<T>(_ keyPath: KeyPath<Xcode.BuildSettings, T>) -> T? {
        configs.prefer(config: preferConfig, keyPath)
    }

    public func prefer<T>(_ keyPath: KeyPath<Xcode.BuildSettings, T?>) -> T? {
        configs.prefer(config: preferConfig, keyPath)
    }

    public var isTest: Bool {
        productType?.isTest == true
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
        headers.filter { header in
            [FileExtension.hpp, .hh, .hxx].contains { header.hasSuffix($0.suffix) }
        }
    }

    public var srcs: [String] {
        filePaths(files.sources)
    }

    public var srcs_c: [String] {
        sources(ofType: "sourcecode.c.c", extensions: [.c])
    }

    public var srcs_objc: [String] {
        sources(ofType: "sourcecode.c.objc", extensions: [.m])
    }

    public var srcs_cpp: [String] {
        sources(ofType: "sourcecode.cpp.cpp", extensions: [.cc, .cp, .cpp, .cxx])
    }

    public var srcs_objcpp: [String] {
        sources(ofType: "sourcecode.cpp.objcpp", extensions: [.mm])
    }

    public var srcs_swift: [String] {
        sources(ofType: "sourcecode.swift", extensions: [.swift])
    }

    public var srcs_metal: [String] {
        sources(ofType: "sourcecode.metal", extensions: [.metal])
    }

    /// Xcode compiles by declared file type, which can disagree with the extension
    /// (`explicitFileType = sourcecode.cpp.objcpp` on a `.m` file is common for
    /// Objective-C code that includes C++).
    private func sources(ofType type: String, extensions: [FileExtension]) -> [String] {
        filePaths(
            files.sources.filter { file in
                if let fileType = file.fileType, Self.compiledFileTypes.contains(fileType) {
                    return fileType == type
                }
                guard let path = file.path else { return false }
                return extensions.contains { path.hasSuffix($0.suffix) }
            })
    }

    private static let compiledFileTypes: Set = [
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

    /// Every `.xcstrings` table the target owns.
    ///
    /// A synchronized root group has no resources build phase to list them in, so
    /// the catalogs arrive as files of no particular kind; a project that still
    /// keeps a resources phase has them there.
    ///
    /// A catalog inside an `.lproj` directory is left out: that one is a
    /// localization of the storyboard or nib it is named after rather than a table
    /// of its own, and Xcode generates no symbols for it.
    public var stringCatalogs: [String] {
        var seen = Set<String>()
        return (filePaths(files.resources) + filePaths(files.others))
            .filter { path in
                path.hasSuffix(".xcstrings")
                    && !path.split(separator: "/").dropLast().contains { $0.hasSuffix(".lproj") }
                    && seen.insert(path).inserted
            }
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

    public var selectedSettings: Xcode.BuildSettings {
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

    private static func filePath(_ file: Xcode.File) -> String? {
        guard let path = file.path?.trimmingCharacters(in: CharacterSet(charactersIn: "/")), !path.isEmpty else {
            return nil
        }
        return "Sources/\(path)"
    }

    private func filePaths(_ files: [Xcode.File]) -> [String] {
        files.compactMap(Self.filePath)
    }
}

extension String {
    /// Directories Xcode treats as one resource, however they were discovered.
    ///
    /// A synchronized root group lists the files inside an asset catalog rather
    /// than the catalog, and the catalog is what `actool` compiles and what the
    /// rules take as an attribute.
    fileprivate static let resourceWrapperExtensions: Set = [
        "bundle",
        "docc",
        "icon",
        "mlpackage",
        "scnassets",
        "xcassets",
        "xcdatamodeld",
        "xcstickers",
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
