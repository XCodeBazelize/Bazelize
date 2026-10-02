#include <metal_stdlib>

#include "ShaderCommon.h"

using namespace metal;

kernel void doubleValues(device float *values [[buffer(0)]],
                         uint index [[thread_position_in_grid]]) {
    values[index] = values[index] * SHADER_FACTOR;
}
