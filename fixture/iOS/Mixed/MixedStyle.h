#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The Objective-C half of a target that also has Swift: it reaches the Swift
/// half through the generated `Mixed-Swift.h`.
@interface MixedStyle : NSObject
+ (NSString *)darkStyleName;
@end

NS_ASSUME_NONNULL_END
