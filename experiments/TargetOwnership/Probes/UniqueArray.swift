// MARK: - OwnedTarget

struct OwnedTarget: ~Copyable {
    let name: String
}

// Check this against both the production macOS 14 floor and macOS 27.
func projectTargets() {
    var targets = UniqueArray<OwnedTarget>()
    targets.append(OwnedTarget(name: "Probe"))
    print(targets.count)
}
