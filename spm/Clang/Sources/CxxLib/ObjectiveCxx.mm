#import <Foundation/Foundation.h>

#include "CxxLib.hpp"

#ifndef CXX_UNSAFE_FLAG
#error "C++ unsafe flags must reach Objective-C++ sources"
#endif

int demo::objectiveCxxLength() {
    return (int)[@"objcxx" length];
}
