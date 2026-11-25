/// Reached as `Pair/Left` and again as `Pair/Right/left`: the two directories
/// link to each other, which is a loop no matter where the walk starts, and
/// SwiftPM compiles this file once all the same.
extension TargetSources {
    public static let paired = true
}
