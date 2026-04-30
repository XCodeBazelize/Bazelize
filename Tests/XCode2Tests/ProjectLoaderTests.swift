import Testing
@testable import XCode2

struct ProjectLoaderTests {
    @Test
    func mergeLocalPackagesKeepsExplicitEntriesFirstAndDeduplicatesByPath() {
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
            discovered: discovered)

        #expect(merged.map(\.relativePath) == ["Local1", "Local2", "Local3"])
        #expect(merged.first?.name == "Local1")
        #expect(merged.last?.name == "Local3")
    }
}
