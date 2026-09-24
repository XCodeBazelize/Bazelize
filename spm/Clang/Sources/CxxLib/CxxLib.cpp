#include "CxxLib.hpp"

/// `cxxLanguageStandard: .gnucxx17`.
#if __cplusplus != 201703L
#error "The package's C++ language standard must reach the compiler"
#endif

#ifndef __GNUC__
#error "A GNU standard is what the manifest named"
#endif

namespace demo {
int twice(int value) {
    return value * 2;
}
}
