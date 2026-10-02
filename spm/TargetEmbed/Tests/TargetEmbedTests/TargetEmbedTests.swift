import TargetEmbed
import Testing

@Test
func anEmbeddedResourceIsInTheBinary() {
    #expect(TargetEmbed.embedded == "embedded")
}
