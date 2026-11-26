extension Xcode {
    public struct CopyFilesDestination: Codable {
        public let path: String?
        public let subfolder: String?
        public let subfolderSpec: UInt?

        package init(path: String?, subfolder: String?, subfolderSpec: UInt?) {
            self.path = path
            self.subfolder = subfolder
            self.subfolderSpec = subfolderSpec
        }
    }
}
