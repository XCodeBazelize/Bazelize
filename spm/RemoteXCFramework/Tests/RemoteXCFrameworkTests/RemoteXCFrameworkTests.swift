import Sparkle
import Testing

@Test
func aRemoteXCFrameworkIsFetchedImportedAndLinked() {
    let result = SUStandardVersionComparator.default.compareVersion("2.0", toVersion: "1.0")
    #expect(result == .orderedDescending)
}
