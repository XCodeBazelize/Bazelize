//
//  Static2.h
//  Static2
//
//  Created by Yume on 2023/2/2.
//

#import <Foundation/Foundation.h>

/// Defined by this target's `OTHER_CFLAGS`, and by `-Xcc` in the Swift flags of
/// whoever imports this module. A generator that drops either setting fails
/// here rather than building something Xcode would not have built.
#if !defined(BAZELIZE_OTHER_FLAGS)
#error "OTHER_CFLAGS / OTHER_SWIFT_FLAGS -Xcc did not reach this compile"
#endif

@interface Static2 : NSObject
+ (NSString*) test;
@end
