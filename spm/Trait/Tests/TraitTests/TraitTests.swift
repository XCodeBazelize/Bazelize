import Testing
import Trait

/// Both ways round: `bazel test //...` has only the default trait, and
/// `bazel test //... --config=Trait.Slow` has `Slow` as well. The test target
/// is part of the package, so the trait is its condition too.
@Test
func theTraitsOnAreTheOnesAskedFor() {
    #if Slow
    #expect(Trait.enabled == ["Fast", "Slow"])
    #expect(Trait.slowExtra)
    #else
    #expect(Trait.enabled == ["Fast"])
    #expect(!Trait.slowExtra)
    #endif
}

@Test
func aDependencysTraitIsEnabledByWhoeverAsked() {
    #expect(Trait.dependencyExtra)
}
