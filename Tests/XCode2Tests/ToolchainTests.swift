import Testing
@testable import XCode2

/// The values Xcode fills in from the toolchain, which a project writes into its
/// `Info.plist` and expects to read back in Xcode's own spelling.
struct ToolchainTests {
    @Test
    func xcodeVersionIsSpelledAsFourDigits() {
        #expect(Toolchain.settings(xcodeVersion: "27.0") == [
            "XCODE_VERSION_ACTUAL": "2700",
            "XCODE_VERSION_MAJOR": "2700",
            "XCODE_VERSION_MINOR": "2700",
        ])

        #expect(Toolchain.settings(xcodeVersion: "14.3") == [
            "XCODE_VERSION_ACTUAL": "1430",
            "XCODE_VERSION_MAJOR": "1400",
            "XCODE_VERSION_MINOR": "1430",
        ])

        /// A patch release counts, and only `ACTUAL` carries it.
        #expect(Toolchain.settings(xcodeVersion: "14.3.1") == [
            "XCODE_VERSION_ACTUAL": "1431",
            "XCODE_VERSION_MAJOR": "1400",
            "XCODE_VERSION_MINOR": "1430",
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
