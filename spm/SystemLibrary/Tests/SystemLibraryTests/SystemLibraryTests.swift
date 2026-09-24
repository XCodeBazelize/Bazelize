import SystemLibrary
import Testing

@Test
func aSystemLibraryImportsHeadersAndLinksItsLibrary() {
    #expect(!SystemLibrary.version.isEmpty)
}

@Test
func aModuleMapLinksTheFrameworkItNames() {
    #expect(SystemLibrary.securityMessage?.isEmpty == false)
}

@Test
func pkgConfigSuppliesTheIncludePath() {
    #expect(SystemLibrary.greeting == 7)
}
