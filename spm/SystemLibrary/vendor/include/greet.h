#pragma once

/// Header-only: what it answers is the proof the header was found at all, and
/// it is found only through the include path `pkg-config` reports.
static inline int greet_value(void) {
    return 7;
}
