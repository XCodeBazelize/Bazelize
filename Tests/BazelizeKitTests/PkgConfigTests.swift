import Testing
@testable import BazelizeKit

struct PkgConfigTests {
    @Test(arguments: [
        (["-Iinclude", "-DVALUE=7", "-Wextra"], ["include"], ["VALUE=7"], ["-Wextra"]),
        (["-I", "include dir", "-D", "VALUE=7", "-Wextra"], ["include dir"], ["VALUE=7"], ["-Wextra"]),
        (["-I", "-D", "-D", "-I", "-Wall", "-I"], ["-D"], ["-I"], ["-Wall"]),
        (["-DFIRST", "-D", "SECOND=2", "-Ione", "-I", "two", "-D"], ["one", "two"], ["FIRST", "SECOND=2"], []),
    ])
    func compilerOptionsKeepTheirOperands(
        flags: [String],
        includes: [String],
        defines: [String],
        other: [String])
    {
        let config = SwiftPM.Generator.PkgConfig(compilerFlags: flags, linkerFlags: ["-lz"])

        #expect(config.includePaths == includes)
        #expect(config.defines == defines)
        #expect(config.otherFlags == other)
        #expect(config.linkerFlags == ["-lz"])
    }
}
