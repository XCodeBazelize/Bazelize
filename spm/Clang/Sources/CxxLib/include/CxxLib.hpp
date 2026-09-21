#pragma once

namespace demo {
/// A C++ function, called from Swift only because the target that calls it is
/// compiled in C++ interoperability mode.
int twice(int value);
}
