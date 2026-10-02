import Testing
import TraitGraph

/// Whatever selection the build was made with, these hold: a trait that enables
/// another is on with it, a condition naming several traits is on when any of
/// them is, and what a dependency's traits were is the dependency's manifest
/// and this one's selection for it — never this package's own selection.
@Test
func theTraitGraphIsClosedOverWhatEachTraitEnables() {
    let state = traitState()

    if state.root.contains("Top") {
        #expect(state.root.contains("Middle"))
    }
    if state.root.contains("Middle") {
        #expect(state.root.contains("Leaf"))
    }
}

@Test
func aConditionOnSeveralTraitsIsOnWhenAnyOfThemIs() {
    let state = traitState()

    #expect(state.anyBranch == (state.root.contains("Middle") || state.root.contains("Alternative")))
}

@Test
func eachDependencyGetsTheTraitsItWasAskedFor() {
    let state = traitState()

    /// `.defaults`: the dependency's own default traits.
    #expect(state.dependencyDefaults)
    /// `traits: []`: no trait at all, defaults included.
    #expect(!state.emptyDependency)
    /// `traits: ["Top"]`: that trait and everything it enables, and nothing of
    /// the dependency's own defaults beyond it.
    #expect(state.explicitDependency == ["Leaf", "Middle", "Top"])
}
