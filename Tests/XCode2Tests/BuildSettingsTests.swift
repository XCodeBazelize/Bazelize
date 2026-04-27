import XCTest
@testable import XCode2

final class BuildSettingsTests: XCTestCase {
    func testBuildSettingsSupportsStringAndArrayValues() {
        let settings = XCode.BuildSettings(
            name: "Debug",
            setting: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "TARGETED_DEVICE_FAMILY": "1 2",
            ]
        )

        XCTAssertEqual(settings["PRODUCT_BUNDLE_IDENTIFIER"], "com.example.app")
        XCTAssertEqual(settings["TARGETED_DEVICE_FAMILY"], "1 2")
    }
}
