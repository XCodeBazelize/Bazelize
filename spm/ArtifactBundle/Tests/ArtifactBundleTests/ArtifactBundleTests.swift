import ArtifactBundle
import Testing

@Test
func theBundledProgramGeneratedTheSource() {
    #expect(greetingFromTool() == "hello from an artifact bundle")
}
