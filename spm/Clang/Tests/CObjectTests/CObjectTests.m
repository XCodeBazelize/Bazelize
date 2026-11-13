#import <XCTest/XCTest.h>

#import "TestHelper.h"

@import CObject;

/// A test target written in Objective-C. SwiftPM allows one, and it compiles
/// like any other C-family target: its own private header beside it, the module
/// it tests imported by name.
@interface CObjectTests : XCTestCase
@end

@implementation CObjectTests

- (void)testTheTargetUnderTestIsReachable {
    XCTAssertEqual([CObject value], 7);
    XCTAssertTrue([CObject flag]);
}

- (void)testThePrivateHeaderBesideTheTestIsCompiled {
    XCTAssertEqual(CObjectTestsExpectedValue(), 7);
}

@end
