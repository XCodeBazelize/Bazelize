extension Xcode {
    public struct CopyFilesDestination: Codable {
        /// `PBXCopyFilesBuildPhase.SubFolder`, stored as Xcode's numeric `dstSubfolderSpec`.
        public enum Subfolder: RawRepresentable, Codable, Equatable {
            case absolutePath
            case wrapper
            case executables
            case resources
            case frameworks
            case sharedSupport
            case plugins
            case productsDirectory
            /// A value this model does not name; kept so it round-trips unchanged.
            case unknown(UInt)

            public init(rawValue: UInt) {
                switch rawValue {
                case 0: self = .absolutePath
                case 1: self = .wrapper
                case 6: self = .executables
                case 7: self = .resources
                case 10: self = .frameworks
                case 12: self = .sharedSupport
                case 13: self = .plugins
                case 16: self = .productsDirectory
                default: self = .unknown(rawValue)
                }
            }

            public var rawValue: UInt {
                switch self {
                case .absolutePath: 0
                case .wrapper: 1
                case .executables: 6
                case .resources: 7
                case .frameworks: 10
                case .sharedSupport: 12
                case .plugins: 13
                case .productsDirectory: 16
                case .unknown(let value): value
                }
            }
        }

        public let path: String?
        public let subfolder: String?
        public let subfolderSpec: Subfolder?

        package init(path: String?, subfolder: String?, subfolderSpec: Subfolder?) {
            self.path = path
            self.subfolder = subfolder
            self.subfolderSpec = subfolderSpec
        }
    }
}
