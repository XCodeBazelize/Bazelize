import Consumer
import Testing

@Test
func definesReachTheCTarget() {
    #expect(Consumer.value == 7)
    #expect(Consumer.flag)
}

@Test
func aPrivateHeaderIsFoundThroughTheSearchPath() {
    #expect(Consumer.internalValue == 41)
}

@Test
func aCTargetReachesItsOwnBundle() {
    #expect(Consumer.greeting == "bundled")
}

@Test
func cxxInteroperabilityWorks() {
    #expect(Consumer.twice == 42)
}

@Test
func assemblyAndObjectiveCxxCompile() {
    #expect(Consumer.assembly == 9)
    #expect(Consumer.objectiveCxxLength == 6)
}
