import PrebuildPlugin
import Testing

@Test
func thePrebuildCommandGeneratedTheSource() {
    #expect(prebuiltValue() == "written before the build")
}
