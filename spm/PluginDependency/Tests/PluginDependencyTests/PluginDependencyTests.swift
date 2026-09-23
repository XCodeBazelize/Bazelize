import PluginDependency
import Testing

@Test
func aPluginFromAnotherPackageRan() {
    #expect(stampedValue() == "stamped PluginDependency")
}

@Test
func aPackageThatIsNothingButAPluginRan() {
    #expect(markedValue() == "marked PluginDependency")
}
