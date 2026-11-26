import Unified
import XCTest

final class UnifiedXCTests: XCTestCase {
    func testBothLanguagesAreOneModule() {
        XCTAssertEqual(SwiftAPI.value, 42)
        XCTAssertEqual(unified_c_value(), 41)
        XCTAssertEqual(SwiftAPI.cValue, 41)
    }

    func testRoundTrip() {
        XCTAssertEqual(SwiftAPI.roundTrip(5), 93)
        XCTAssertEqual(unified_round_trip(5), 93)
    }
}
