// MARK: - OwnedTarget

struct OwnedTarget: ~Copyable {
    let name: String
}

// Project.targets currently uses this standard-library collection contract.
func projectTargets(_: [OwnedTarget]) { }
