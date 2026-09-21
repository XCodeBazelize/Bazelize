import Testing
import Trait

@Test
func onlyTheDefaultTraitIsEnabled() {
    #expect(Trait.enabled == ["Fast"])
}

@Test
func aDependencysTraitIsEnabledByWhoeverAsked() {
    #expect(Trait.dependencyExtra)
}
