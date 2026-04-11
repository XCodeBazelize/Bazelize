public extension XCode {
    struct CopyFilesDestination: Codable {
        public let path: String?
        public let subfolder: String?
        public let subfolderSpec: UInt?
    }
}
