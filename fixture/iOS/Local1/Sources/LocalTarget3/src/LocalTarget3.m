//
//  Framework.m
//  Framework3
//
//  Created by Yume on 2023/2/2.
//

#import "LocalTarget3.h"

@implementation LocalTarget3
+ (int) test {
    return 1 << 4;
}
- (int) test2 {
    return LocalTarget3.test;
}
@end
