import RemoteArtifactBundle
import Testing

@Test
func theFetchedProgramRan() {
    /// The version the manifest pins, which only the program itself can say.
    #expect(versionOfTheBundledTool() == "3.8.0")
}
