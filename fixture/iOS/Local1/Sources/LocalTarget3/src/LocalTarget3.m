//
//  Framework.m
//  Framework3
//
//  Created by Yume on 2023/2/2.
//

#import "LocalTarget3.h"

/// Written by the Local1Gen build tool plugin, which SwiftPM compiles into this
/// target: its header is on no search path of a hand-written source, so the
/// symbol is declared rather than included.
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
