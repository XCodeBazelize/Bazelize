#ifndef C_PAIR_INNER_H
#define C_PAIR_INNER_H

/// A header of the target's own module, from one of the module beside it.
#include "CPairOuter.h"
#include "CPairInnerDetail.h"

#ifdef __cplusplus
extern "C" {
#endif
/// Declared by the module map beside this header, not by the target: an
/// `import CPairInner` resolves only if that map reaches the compiler.
int pair_inner_value(void);
#ifdef __cplusplus
}
#endif

static inline int pair_inner_detail_value(void) {
    return C_PAIR_INNER_DETAIL;
}

#endif
