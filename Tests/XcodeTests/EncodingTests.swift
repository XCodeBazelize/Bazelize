import Foundation
import Testing
@testable import Xcode

struct EncodingTests {
    @Test
    func filesEncodingOmitsEmptyCopyFiles() throws {
        let value = Xcode.Files(
            sources: [],
            headers: [],
            resources: [],
            frameworks: [],
            copyFiles: [],
            others: [])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json == "{}")
    }

    @Test(arguments: [0, 1, 6, 7, 10, 12, 13, 16, 999] as [UInt])
    func copyDestinationsKeepNumericJSON(spec: UInt) throws {
        let json = Data("{\"path\":\"Assets\",\"subfolderSpec\":\(spec)}".utf8)
        let destination = try JSONDecoder().decode(Xcode.CopyFilesDestination.self, from: json)
        let encoded = try JSONEncoder().encode(destination)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        #expect(object["subfolderSpec"] as? UInt == spec)
        #expect(object["path"] as? String == "Assets")
    }
}
