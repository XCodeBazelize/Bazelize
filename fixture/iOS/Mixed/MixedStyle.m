#import "MixedStyle.h"

// The generated header imports the binary framework's module, because the
// Swift declaration below it is spelled with one of that framework's types.
#import <Mixed/Mixed-Swift.h>

@implementation MixedStyle
+ (NSString *)darkStyleName {
    return [MixedHUD nameOf:SVProgressHUDStyleDark];
}
@end
