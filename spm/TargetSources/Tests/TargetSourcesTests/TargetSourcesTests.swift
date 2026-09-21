import TargetSources
import Testing

@Test
func listedSourcesAreCompiled() {
    #expect(TargetSources.compiled)
    #expect(TargetSources.kept)
}
