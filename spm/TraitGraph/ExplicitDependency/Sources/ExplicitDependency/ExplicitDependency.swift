public let explicitDependencyTraits: Set<String> = {
    var traits: Set<String> = []
    #if Leaf
    traits.insert("Leaf")
    #endif
    #if Middle
    traits.insert("Middle")
    #endif
    #if Top
    traits.insert("Top")
    #endif
    return traits
}()
