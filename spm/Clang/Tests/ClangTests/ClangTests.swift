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

@Test
func oneTargetIsTwoModules() {
    #expect(Consumer.pair.outer == 6)
    #expect(Consumer.pair.inner == 5)
    #expect(Consumer.pairInner.detail == 2)
    #expect(Consumer.pairInner.extras == 8)
    #expect(Consumer.pairPart == 11)
}

@Test
func everyModuleARootMapDeclaresIsImportable() {
    #expect(Consumer.many.total == 25)
    #expect(Consumer.many.extra == 13)
    #expect(Consumer.hiddenOnly == 21)
}
