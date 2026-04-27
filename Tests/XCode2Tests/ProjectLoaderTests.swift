import XCTest
@testable import XCode2

final class ProjectLoaderTests: XCTestCase {
    func testMergeLocalPackagesKeepsExplicitEntriesFirstAndDeduplicatesByPath() {
        let explicit: [XCode.LocalPackage] = [
            .init(name: "Local1", relativePath: "Local1"),
            .init(name: "Local2", relativePath: "Local2"),
        ]
        let discovered: [XCode.LocalPackage] = [
            .init(name: "Local1 (Scanned)", relativePath: "Local1"),
            .init(name: "Local3", relativePath: "Local3"),
        ]

        let merged = ProjectLoader.mergeLocalPackages(
            explicit: explicit,
            discovered: discovered
        )

        XCTAssertEqual(merged.map(\.relativePath), ["Local1", "Local2", "Local3"])
        XCTAssertEqual(merged.first?.name, "Local1")
        XCTAssertEqual(merged.last?.name, "Local3")
    }
}
