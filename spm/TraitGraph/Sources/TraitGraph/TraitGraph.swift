import DefaultDependency
import EmptyDependency
import ExplicitDependency

public struct TraitState: Equatable, Sendable {
    public let root: Set<String>
    public let anyBranch: Bool
    public let dependencyDefaults: Bool
    public let emptyDependency: Bool
    public let explicitDependency: Set<String>
}

public func traitState() -> TraitState {
    var root: Set<String> = []
    #if Leaf
    root.insert("Leaf")
    #endif
    #if Middle
    root.insert("Middle")
    #endif
    #if Top
    root.insert("Top")
    #endif
    #if Alternative
    root.insert("Alternative")
    #endif

    return TraitState(
        root: root,
        anyBranch: {
            #if ANY_BRANCH
            true
            #else
            false
            #endif
        }(),
        dependencyDefaults: defaultDependencyEnabled,
        emptyDependency: emptyDependencyEnabled,
        explicitDependency: explicitDependencyTraits)
}
