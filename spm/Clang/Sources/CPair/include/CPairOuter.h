#ifndef C_PAIR_OUTER_H
#define C_PAIR_OUTER_H

#ifdef __cplusplus
extern "C" {
#endif
/// In the module SwiftPM names after the target: its umbrella is `include`,
/// whose walk does not enter the `CPairInner` link, so this header is the
/// module's only one. Were the other one in it too, each module would include
/// the other.
int pair_outer_value(void);
#ifdef __cplusplus
}
#endif

#endif
