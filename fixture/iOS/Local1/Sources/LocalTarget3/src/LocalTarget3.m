//
//  Framework.m
//  Framework3
//
//  Created by Yume on 2023/2/2.
//

#import "LocalTarget3.h"

@implementation LocalTarget3
/// The plugin's C source is compiled into this target when the toolchain runs
/// the plugin for a C-family target, which Swift 6.3 does not and 6.4 does.
/// Nothing here calls into it, so the fixture links either way.
+ (int) test {
    return 1 << 4;
}
- (int) test2 {
    return LocalTarget3.test;
}
@end
