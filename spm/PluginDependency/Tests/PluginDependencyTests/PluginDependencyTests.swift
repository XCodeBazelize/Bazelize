import PluginDependency
import Testing

@Test
func aPluginFromAnotherPackageRan() {
    #expect(stampedValue() == "stamped PluginDependency")
}
