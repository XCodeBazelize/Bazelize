#ifndef UNIFIED_H
#define UNIFIED_H

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#else
#include <stddef.h>
#endif

#if defined(UNIFIED_C_FLAG) && UNIFIED_C_BONUS == 1
#define UNIFIED_HEADER_FLAG 1
#else
#define UNIFIED_HEADER_FLAG 0
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// 40 from a private header, plus the package's `UNIFIED_C_BONUS` define: 41.
int unified_c_value(void);
/// 1 when `UNIFIED_C_FLAG` reached the C compile.
int unified_c_flag(void);
/// 1 when the package's C language standard (`c11`) reached the C compile.
int unified_c_is_c11(void);

#ifdef __OBJC__
/// Objective-C calling back into Swift: `UnifiedSwiftBridge.step(seed)` plus
/// `unified_c_value()`. For 5 that is (5 * 2 + 42) + 41 = 93.
NSInteger unified_round_trip(NSInteger seed);
#endif

#ifdef __cplusplus
}
#endif

#endif
