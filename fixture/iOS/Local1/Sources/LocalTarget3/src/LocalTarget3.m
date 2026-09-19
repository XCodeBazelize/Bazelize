//
//  Framework.m
//  Framework3
//
//  Created by Yume on 2023/2/2.
//

#import "LocalTarget3.h"

/// Written by the Local1Gen build tool plugin, compiled into this target by the
/// rules bazelize generates: bazelize runs the plugin itself, so this holds on
/// every toolchain rather than only the ones whose `swift build` runs a plugin
/// for a C-family target.
extern int local1_plugin_value(void);

@implementation LocalTarget3
+ (int) test {
    return 1 << 4;
}
- (int) test2 {
    return LocalTarget3.test;
}
- (int) generated {
    return local1_plugin_value();
}
@end
