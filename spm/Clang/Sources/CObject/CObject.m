#import "CObject.h"

#import "CInternal.h"
#ifndef C_UNSAFE_FLAG
#error "C unsafe flags must reach Objective-C sources"
#endif

@implementation CObject

+ (int)value {
#ifdef C_VALUE
    return C_VALUE;
#else
    return 0;
#endif
}

+ (BOOL)flag {
#ifdef C_FLAG
    return YES;
#else
    return NO;
#endif
}

+ (int)internalValue {
    return CInternalValue;
}

+ (nullable NSString *)greeting {
    NSURL *url = [SWIFTPM_MODULE_BUNDLE URLForResource:@"greeting" withExtension:@"txt"];
    if (url == nil) { return nil; }

    NSString *contents = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    return [contents stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

@end
