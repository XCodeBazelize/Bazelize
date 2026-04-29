import Foundation
import Testing
@testable import XCode2

struct EncodingTests {
    @Test
    func filesEncodingOmitsEmptyCopyFiles() throws {
        let value = XCode.Files(
            sources: [],
            headers: [],
            resources: [],
            frameworks: [],
            copyFiles: [],
            others: []
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json == "{}")
    }
}
