#include <metal_stdlib>

using namespace metal;

kernel void doubleValues(device float *values [[buffer(0)]],
                         uint index [[thread_position_in_grid]]) {
    values[index] = values[index] * 2.0;
}
