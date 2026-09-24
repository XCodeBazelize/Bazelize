import Consumer
import XCTest

/// The other test framework: a package's tests are XCTest as often as they are
/// swift-testing, and the two are bundled and run differently enough that a
/// suite passing says nothing about the other kind.
final class ClangXCTests: XCTestCase {
    func testDefinesReachTheCTarget() {
        XCTAssertEqual(Consumer.value, 7)
        XCTAssertTrue(Consumer.flag)
    }

    func testAssemblyAndObjectiveCxxCompile() {
        XCTAssertEqual(Consumer.assembly, 9)
        XCTAssertEqual(Consumer.objectiveCxxLength, 6)
    }
}
