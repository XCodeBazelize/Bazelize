import TargetResource
import Testing

@Test
func aCopiedResourceKeepsItsDirectory() {
    #expect(TargetResource.copied == "copied")
}

@Test
func aProcessedResourceIsInTheBundle() {
    #expect(TargetResource.processed == "processed")
}

@Test
func anEmbeddedResourceIsInTheBinary() {
    #expect(TargetResource.embedded == "embedded")
}
