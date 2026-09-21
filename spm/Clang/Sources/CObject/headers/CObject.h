#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CObject : NSObject
/// The value of a define the manifest gives a value to.
+ (int)value;
/// Whether a define the manifest states without one is defined.
+ (BOOL)flag;
/// What a header found through the target's own search path says.
+ (int)internalValue;
/// A resource, read out of the bundle the target was given.
+ (nullable NSString *)greeting;
@end

NS_ASSUME_NONNULL_END
