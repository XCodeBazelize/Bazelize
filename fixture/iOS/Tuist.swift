import ProjectDescription

/// Stops Tuist from walking up into the Bazelize repository, whose `Package.swift`
/// belongs to the generator rather than to this fixture.
let tuist = Tuist(project: .tuist())
