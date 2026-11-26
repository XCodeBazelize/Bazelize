extension Xcode {
    public struct BuildPhaseFile: Codable {
        public let name: String?
        public let path: String?
        public let fileType: String?
        public let compilerFlags: String?
        public let attributes: [String]

        package init(name: String?, path: String?, fileType: String?, compilerFlags: String?, attributes: [String]) {
            self.name = name
            self.path = path
            self.fileType = fileType
            self.compilerFlags = compilerFlags
            self.attributes = attributes
        }
    }
}
