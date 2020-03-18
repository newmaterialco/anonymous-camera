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

vertex ImageColorInOut oneInputVertex(constant packed_float2 *position [[buffer(0)]], constant packed_float2 *texturecoord [[buffer(1)]], uint vid [[vertex_id]], constant VertexUniforms& uniforms [[ buffer(3) ]]) {
    ImageColorInOut outputVertices;
    outputVertices.position = float4((position[vid].x * uniforms.mirrored) * uniforms.aspectScale, position[vid].y * uniforms.aspectScale, 0, 1.0);
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
