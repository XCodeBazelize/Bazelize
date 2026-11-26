#ifndef C_MANY_H
#define C_MANY_H

#ifdef __cplusplus
extern "C" {
#endif
/// The target's own module, declared by the map it ships.
int many_total(void);
#ifdef __cplusplus
}
#endif

static inline int many_value(void) {
    return 12;
}

#endif
