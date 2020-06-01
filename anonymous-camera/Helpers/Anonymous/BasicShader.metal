//
//  YUVToRGBShader.metal
//  ShaderKit
//
//  Created by Alisdair Mills on 03/12/2019.
//  Copyright © 2019 amills. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"
#import "ShaderMethods.h"
using namespace metal;

typedef struct {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
} ImageVertex;

float4 ycbcrToRGBTransform(float4 y, float4 CbCr) {
    const metal::float4x4 ycbcrToRGBTransform = metal::float4x4(
      float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
      float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
      float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
      float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );
    float4 ycbcr = float4(y.r, CbCr.rg, 1.0);
    return ycbcrToRGBTransform * ycbcr;
}

unsigned Loki::TausStep(const unsigned z, const int s1, const int s2, const int s3, const unsigned M)
{
    unsigned b=(((z << s1) ^ z) >> s2);
    return (((z & M) << s3) ^ b);
}

thread Loki::Loki(const unsigned seed1, const unsigned seed2, const unsigned seed3) {
    unsigned seed = seed1 * 1099087573UL;
    unsigned seedb = seed2 * 1099087573UL;
    unsigned seedc = seed3 * 1099087573UL;

    // Round 1: Randomise seed
    unsigned z1 = TausStep(seed,13,19,12,429496729UL);
    unsigned z2 = TausStep(seed,2,25,4,4294967288UL);
    unsigned z3 = TausStep(seed,3,11,17,429496280UL);
    unsigned z4 = (1664525*seed + 1013904223UL);

    // Round 2: Randomise seed again using second seed
    unsigned r1 = (z1^z2^z3^z4^seedb);

    z1 = TausStep(r1,13,19,12,429496729UL);
    z2 = TausStep(r1,2,25,4,4294967288UL);
    z3 = TausStep(r1,3,11,17,429496280UL);
    z4 = (1664525*r1 + 1013904223UL);

    // Round 3: Randomise seed again using third seed
    r1 = (z1^z2^z3^z4^seedc);

    z1 = TausStep(r1,13,19,12,429496729UL);
    z2 = TausStep(r1,2,25,4,4294967288UL);
    z3 = TausStep(r1,3,11,17,429496280UL);
    z4 = (1664525*r1 + 1013904223UL);

    this->seed = (z1^z2^z3^z4) * 2.3283064365387e-10;
}

thread float Loki::rand() {
    unsigned hashed_seed = this->seed * 1099087573UL;

    unsigned z1 = TausStep(hashed_seed,13,19,12,429496729UL);
    unsigned z2 = TausStep(hashed_seed,2,25,4,4294967288UL);
    unsigned z3 = TausStep(hashed_seed,3,11,17,429496280UL);
    unsigned z4 = (1664525*hashed_seed + 1013904223UL);

    thread float old_seed = this->seed;

    this->seed = (z1^z2^z3^z4) * 2.3283064365387e-10;

    return old_seed;
}

vertex ImageColorInOut oneInputVertex(constant packed_float2 *position [[buffer(0)]], constant packed_float2 *texturecoord [[buffer(1)]], uint vid [[vertex_id]], constant VertexUniforms& uniforms [[ buffer(3) ]]) {
    ImageColorInOut outputVertices;
    outputVertices.position = float4((position[vid].x * uniforms.mirrored) * uniforms.aspectScale, position[vid].y * uniforms.aspectScale, 0, 1.0);
    outputVertices.texCoord = texturecoord[vid];
    return outputVertices;
}

vertex ImageColorInOut nonScaledInputVertex(constant packed_float2 *position [[buffer(0)]], constant packed_float2 *texturecoord [[buffer(1)]], uint vid [[vertex_id]], constant VertexUniforms& uniforms [[ buffer(3) ]]) {
    ImageColorInOut outputVertices;
    outputVertices.position = float4(-position[vid].x, position[vid].y, 0, 1.0);
    outputVertices.texCoord = texturecoord[vid];
    return outputVertices;
}

fragment float4 yuvToRgbFragment(
                                 ImageColorInOut in [[stage_in]],
                                 texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                                 texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]]) {
    
    constexpr sampler colorSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    return ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
}
