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
}
