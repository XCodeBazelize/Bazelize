import Testing
@testable import RegistryPackage

@Test
func theRegistryDependencyIsLinked() {
    #expect(RegistryPackage.greeting == "from the registry")
}
