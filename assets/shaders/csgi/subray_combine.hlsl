#include "common.hlsl"
#include "../inc/pack_unpack.hlsl"

[[vk::binding(0)]] Texture3D<float3> indirect_tex;
[[vk::binding(1)]] Texture3D<float4> direct_tex;
[[vk::binding(2)]] RWTexture3D<float3> output_tex;

#define CLAMP_STRATEGY_NONE 0
#define CLAMP_STRATEGY_STRONG_DIRECTIONAL 1
#define CLAMP_STRATEGY_WEAK_DIRECTIONAL 2
#define CLAMP_STRATEGY_WEAK_OMNI 3
#define CLAMP_STRATEGY_STRONG_OMNI 1

#define CLAMP_STRATEGY CLAMP_STRATEGY_WEAK_OMNI
//#define CLAMP_STRATEGY CLAMP_STRATEGY_NONE
//#define CLAMP_STRATEGY CLAMP_STRATEGY_STRONG_OMNI

#if CLAMP_STRATEGY == CLAMP_STRATEGY_NONE
    #define USE_INDIRECT_CLAMP 0
    #define INDIRECT_CLAMP_DIRECTIONAL 0
    #define INDIRECT_CLAMP_AMOUNT 0
#elif CLAMP_STRATEGY == CLAMP_STRATEGY_STRONG_DIRECTIONAL
    #define USE_INDIRECT_CLAMP 1
    #define INDIRECT_CLAMP_DIRECTIONAL 1
    #define INDIRECT_CLAMP_AMOUNT 1.0
#elif CLAMP_STRATEGY == CLAMP_STRATEGY_WEAK_DIRECTIONAL
    #define USE_INDIRECT_CLAMP 1
    #define INDIRECT_CLAMP_DIRECTIONAL 1
    #define INDIRECT_CLAMP_AMOUNT 0.5
#elif CLAMP_STRATEGY == CLAMP_STRATEGY_WEAK_OMNI
    #define USE_INDIRECT_CLAMP 1
    #define INDIRECT_CLAMP_DIRECTIONAL 0
    #define INDIRECT_CLAMP_AMOUNT 0.25
#elif CLAMP_STRATEGY == CLAMP_STRATEGY_STRONG_OMNI
    #define USE_INDIRECT_CLAMP 1
    #define INDIRECT_CLAMP_DIRECTIONAL 0
    #define INDIRECT_CLAMP_AMOUNT 1.0
#endif

float3 subray_combine_indirect(uint subray_count, uint3 vx) {
    float3 result = 0.0.xxx;

    [unroll]
    for (uint subray = 0; subray < subray_count; ++subray) {
        uint3 subray_offset = uint3(0, subray * CSGI_VOLUME_DIMS, 0);
        result += indirect_tex[vx + subray_offset];
    }

    return result / subray_count;
}

[numthreads(4, 4, 4)]
void main(in uint3 vx : SV_DispatchThreadID) {
    const uint dir_idx = vx.x / CSGI_VOLUME_DIMS;
    const float3 indirect_dir = CSGI_INDIRECT_DIRS[dir_idx];
    const uint3 direct_vx = vx % CSGI_VOLUME_DIMS;

    float opacity = 0;
    #if USE_INDIRECT_CLAMP
        #if 0
            for (uint i = 0; i < 6; i += 2) {
                float3 direct_dir = CSGI_SLICE_DIRS[i];

                // Only block directions that share axes
                if (abs(dot(direct_dir, indirect_dir)) > 0)
                {
                    float a0 = direct_tex[direct_vx + uint3(i * CSGI_VOLUME_DIMS, 0, 0)].a;
                    float a1 = direct_tex[direct_vx + uint3((i+1) * CSGI_VOLUME_DIMS, 0, 0)].a;
                    //opacity += 100 * a0 * a1;    // Only block conflicting directions; LEAKS
                    opacity += a0 + a1;
                }
            }
        #else
            for (uint i = 0; i < 6; ++i) {
                float3 direct_dir = CSGI_SLICE_DIRS[i];

                // Only block relevant directions
                if (!INDIRECT_CLAMP_DIRECTIONAL || dot(direct_dir, indirect_dir) > 0) {
                    float a0 = direct_tex[direct_vx + uint3(i * CSGI_VOLUME_DIMS, 0, 0)].a;
                    opacity += a0 * 1.0;
                }
            }
        #endif
    #endif

    float light_mult = 1.0 - saturate(opacity * INDIRECT_CLAMP_AMOUNT);

    float3 result;
    if (dir_idx < 6) {
        result = subray_combine_indirect(4, vx);
    } else {
        result = subray_combine_indirect(3, vx);
    }

    output_tex[vx] = prequant_shift_11_11_10(lerp(output_tex[vx], result, 1) * light_mult);
}
