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
