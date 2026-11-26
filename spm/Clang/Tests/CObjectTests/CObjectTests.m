#import <XCTest/XCTest.h>

#import "TestHelper.h"

@import CHiddenOnly;
@import CManyExtra;
@import CObject;
@import CPair;
@import CPairInner;
@import CPairInner.Extras;
@import CPairParts.CPairPartA;
@import CPairParts.CPairPartB;

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

- (void)testAModuleANestedModuleMapDeclaresIsImportable {
    XCTAssertEqual(pair_inner_value(), 5);
    XCTAssertEqual(pair_inner_detail_value(), 2);
    XCTAssertEqual(pair_inner_extras_value(), 8);
}

/// A real subdirectory of the target's headers whose map infers a submodule
/// per header. Whether the target's own module re-exports it is the build
/// system's to decide — SwiftPM's two disagree — so each is imported by name.
- (void)testSubmodulesInferredFromARealSubdirectoryAreImportable {
    XCTAssertEqual(pair_part_a_value(), 11);
    XCTAssertEqual(pair_part_b_value(), 44);
}

- (void)testEveryModuleARootMapDeclaresIsImportable {
    XCTAssertEqual(many_extra_value(), 13);
    XCTAssertEqual(hidden_only_value(), 21);
}

@end
