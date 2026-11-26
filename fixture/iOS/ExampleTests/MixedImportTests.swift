import Mixed
/// The test spells an enum of the binary framework itself.
import SVProgressHUDShare
import XCTest

/// One `import` of a framework that is Swift and Objective-C reaches both
/// halves: `MixedStyle` is the Objective-C class, `MixedHUD` the Swift one.
final class MixedImportTests: XCTestCase {
    func testBothHalvesOfAMixedFramework() {
        XCTAssertEqual(MixedStyle.darkStyleName(), "dark")
        XCTAssertEqual(MixedHUD.name(of: .light), "light")
    }
}
