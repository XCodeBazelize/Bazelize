#import <XCTest/XCTest.h>
@import Mixed;
/// The test spells an enum of the binary framework itself.
@import SVProgressHUDShare;

/// One `@import` of a framework that is Swift and Objective-C reaches both
/// halves: `MixedStyle` is the Objective-C class, `MixedHUD` the Swift one.
@interface MixedImportTests : XCTestCase
@end

@implementation MixedImportTests

- (void)testBothHalvesOfAMixedFramework {
    XCTAssertEqualObjects([MixedStyle darkStyleName], @"dark");
    XCTAssertEqualObjects([MixedHUD nameOf:SVProgressHUDStyleLight], @"light");
}

@end
