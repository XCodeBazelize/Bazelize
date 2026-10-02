import Foundation
import TraitGraph

let expected = Set(CommandLine.arguments.dropFirst())
let state = traitState()

guard state.root == expected else {
    fatalError("expected \(expected.sorted()), got \(state.root.sorted())")
}
guard state.anyBranch == (expected.contains("Middle") || expected.contains("Alternative")) else {
    fatalError("multi-trait condition did not follow the selected traits")
}
guard state.dependencyDefaults, !state.emptyDependency,
      state.explicitDependency == ["Leaf", "Middle", "Top"]
else {
    fatalError("dependency trait policy was not preserved")
}

print(state.root.sorted().joined(separator: ","))
