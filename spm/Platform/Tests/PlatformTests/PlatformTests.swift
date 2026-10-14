import Foundation
import Platform
import Testing

@Test
func theDeclaredDeploymentTargetIsWhatTheTargetIsBuiltFor() {
    #expect(Platform.deploymentTargetIsDeclared)
}

@Test
func theSelectedPlatformDependencyIsUsableAtRuntime() {
    #if targetEnvironment(macCatalyst)
    #expect(Platform.selectedDependency == "Mac Catalyst")
    #elseif os(macOS)
    #expect(Platform.selectedDependency == "macOS")
    #elseif os(iOS)
    #expect(Platform.selectedDependency == "iOS")
    #elseif os(tvOS)
    #expect(Platform.selectedDependency == "tvOS")
    #elseif os(watchOS)
    #expect(Platform.selectedDependency == "watchOS")
    #elseif os(visionOS)
    #expect(Platform.selectedDependency == "visionOS")
    #endif
}

@Test
func aResourceIsReadableInTheSelectedPlatformBundle() throws {
    let url = try #require(Bundle.module.url(forResource: "platform", withExtension: "txt"))
    let contents = try String(contentsOf: url, encoding: .utf8)

    #expect(contents.trimmingCharacters(in: .whitespacesAndNewlines) == "platform fixture")
}
