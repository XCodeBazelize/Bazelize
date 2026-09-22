import SwiftSettings
import Testing

@Test
func defaultIsolationPutsTheTargetOnTheMainActor() async {
    /// Off the main actor to begin with: reaching it is the setting's doing.
    let isolated = await Task.detached { await SettingProbe.isolation() }.value
    #expect(isolated)
}

@Test @MainActor
func linkedLibraryAndFrameworkAreLinked() {
    #expect(SettingProbe.checksum() == 0x3524_41C2)
    #expect(SettingProbe.frameworkMessage()?.isEmpty == false)
}

@Test @MainActor
func linkerUnsafeFlagsReachTheLink() {
    #expect(SettingProbe.aliased() == 42)
}
