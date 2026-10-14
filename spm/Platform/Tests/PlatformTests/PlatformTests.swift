import Foundation
import Platform
import Testing

@Test
func theDeclaredDeploymentTargetIsWhatTheTargetIsBuiltFor() {
    #expect(Platform.deploymentTargetIsDeclared)
}

@Test
func theSelectedPlatformDependencyIsUsableAtRuntime() {
    #if os(iOS)
    #expect(Platform.selectedDependency == "iOS")
    #else
    #expect(Platform.selectedDependency == "macOS")
    #endif
}

@Test
func aResourceIsReadableInTheSelectedPlatformBundle() throws {
    let url = try #require(Bundle.module.url(forResource: "platform", withExtension: "txt"))
    let contents = try String(contentsOf: url, encoding: .utf8)

    #expect(contents.trimmingCharacters(in: .whitespacesAndNewlines) == "platform fixture")
}
