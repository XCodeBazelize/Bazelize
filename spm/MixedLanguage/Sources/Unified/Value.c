#include "Unified.h"
#include "Private.h"

#ifndef UNIFIED_C_BONUS
#error "UNIFIED_C_BONUS must come from the package's cSettings"
#endif

int unified_c_value(void) {
    return UNIFIED_PRIVATE_BASE + UNIFIED_C_BONUS;
}

int unified_c_flag(void) {
#ifdef UNIFIED_C_FLAG
    return 1;
#else
    return 0;
#endif
}

int unified_c_is_c11(void) {
    return __STDC_VERSION__ == 201112L;
}
