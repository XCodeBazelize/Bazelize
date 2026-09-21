import Conditional
import Testing

@Test
func theUnconditionalDependencyIsAlwaysLinked() {
    #expect(Conditional.always == 1)
}

/// Both ways round: `bazel test //...` has the trait off, and
/// `bazel test //... --config=DependencyCondition.Extras` has it on.
@Test
func aTraitDecidesWhetherItsDependencyIsLinked() {
    #if EXTRAS
    #expect(Conditional.extras == 3)
    #else
    #expect(Conditional.extras == nil)
    #endif
}
