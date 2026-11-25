#ifndef C_HIDDEN_ONLY_H
#define C_HIDDEN_ONLY_H

#ifdef __cplusplus
extern "C" {
#endif
/// The only module the target's map declares: there is no `CHidden` to
/// import, and this is what a dependent imports instead.
int hidden_only_value(void);
#ifdef __cplusplus
}
#endif

#endif
