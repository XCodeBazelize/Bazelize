import Conditional
import Testing

@Test
func onlyTheUnconditionalDependencyIsLinked() {
    #expect(Conditional.always == 1)
}
