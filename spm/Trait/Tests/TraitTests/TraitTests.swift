import Testing
import Trait

/// The test target and library target must receive the same trait conditions,
/// for every combination SwiftPM accepts.
@Test
func theTraitsOnAreTheOnesAskedFor() {
    #if Fast && Slow
    #expect(Trait.enabled == ["Fast", "Slow"])
    #elseif Fast
    #expect(Trait.enabled == ["Fast"])
    #elseif Slow
    #expect(Trait.enabled == ["Slow"])
    #else
    #expect(Trait.enabled == [])
    #endif
}

@Test
func aDependencysTraitIsEnabledByWhoeverAsked() {
    #expect(Trait.dependencyExtra)
}
