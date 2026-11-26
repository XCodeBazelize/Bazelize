// MARK: - Xcode.SourceTree

extension Xcode {
    /// What a file reference's path is relative to, as the project file spells
    /// it: a build setting Xcode resolves while building, or one of the trees the
    /// project format itself defines.
    public enum SourceTree: Hashable, Sendable {
        /// `<group>`: the group that holds the reference. It names no build
        /// setting; it exists only inside the project file.
        case group
        /// `<absolute>`: the path is absolute.
        case absolute
        /// `SOURCE_ROOT`: the directory holding the project.
        case sourceRoot
        /// `BUILT_PRODUCTS_DIR`: another target's product.
        case buildProductsDir
        /// `SDKROOT`: a framework or library of the SDK.
        case sdkRoot
        /// `DEVELOPER_DIR`: something the Xcode installation ships.
        case developerDir
        /// Any other build setting the project names, or `""` when the reference
        /// states none.
        case other(String)
    }
}

// MARK: - Xcode.SourceTree + RawRepresentable, Codable

extension Xcode.SourceTree: RawRepresentable, Codable {
    public init(rawValue: String) {
        self = switch rawValue {
        case "<group>": .group
        case "<absolute>": .absolute
        case "SOURCE_ROOT": .sourceRoot
        case "BUILT_PRODUCTS_DIR": .buildProductsDir
        case "SDKROOT": .sdkRoot
        case "DEVELOPER_DIR": .developerDir
        default: .other(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .group: "<group>"
        case .absolute: "<absolute>"
        case .sourceRoot: "SOURCE_ROOT"
        case .buildProductsDir: "BUILT_PRODUCTS_DIR"
        case .sdkRoot: "SDKROOT"
        case .developerDir: "DEVELOPER_DIR"
        case .other(let value): value
        }
    }
}
