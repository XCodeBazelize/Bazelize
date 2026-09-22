import Conventional
import TargetPath
import Testing

@Test
func targetLivesWhereThePathSays() {
    #expect(TargetPath.directory == "Code/Library")
}

@Test
func aTargetWithoutAPathIsFoundInAConventionalRoot() {
    #expect(conventional == "src")
}
