import Testing
@testable import Xcode
@testable import XcodeLoader

/// The values Xcode fills in from the toolchain, which a project writes into its
/// `Info.plist` and expects to read back in Xcode's own spelling.
struct ToolchainTests {
    @Test
    func xcodeVersionIsSpelledAsFourDigits() {
        #expect(Toolchain.settings(xcodeVersion: "27.0") == [
            .xcodeVersionActual: "2700",
            .xcodeVersionMajor: "2700",
            .xcodeVersionMinor: "2700",
        ])

        #expect(Toolchain.settings(xcodeVersion: "14.3") == [
            .xcodeVersionActual: "1430",
            .xcodeVersionMajor: "1400",
            .xcodeVersionMinor: "1430",
        ])

        /// A patch release counts, and only `ACTUAL` carries it.
        #expect(Toolchain.settings(xcodeVersion: "14.3.1") == [
            .xcodeVersionActual: "1431",
            .xcodeVersionMajor: "1400",
            .xcodeVersionMinor: "1430",
        ])
    }

    @Test
    func aVersionThatIsNoVersionSetsNothing() {
        /// A toolchain that cannot be asked leaves the settings unset, so the
        /// reference stays unresolved and the key that carries it is dropped —
        /// rather than reaching a bundle as `0`.
        #expect(Toolchain.settings(xcodeVersion: "").isEmpty)
        #expect(Toolchain.settings(xcodeVersion: "Xcode").isEmpty)
    }
}
