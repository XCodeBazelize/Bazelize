extension Xcode {
    public struct File: Codable {
        public let name: String?
        public let path: String?
        public let fullPath: String?
        public let label: String?
        public let fileType: String?
        public let sourceTree: SourceTree
        public let buildPhase: String?
        public let compilerFlags: String?
        public let attributes: [String]

        package init(
            name: String?,
            path: String?,
            fullPath: String?,
            label: String?,
            fileType: String?,
            sourceTree: SourceTree,
            buildPhase: String?,
            compilerFlags: String?,
            attributes: [String])
        {
            self.name = name
            self.path = path
            self.fullPath = fullPath
            self.label = label
            self.fileType = fileType
            self.sourceTree = sourceTree
            self.buildPhase = buildPhase
            self.compilerFlags = compilerFlags
            self.attributes = attributes
        }
    }
}
