//
//  FaceBlurShader.metal
//  anonymous-camera
//
//  Created by Alisdair Mills on 06/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//


#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"
#import "ShaderMethods.h"
using namespace metal;

fragment float4 faceBlurFragment(ImageColorInOut in [[stage_in]],
                        texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                        texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]],
                        texture2d<float, access::sample> blurTexture [[ texture(3) ]],
                        texture1d<float, access::read> rects [[ texture(4) ]],
                        constant FaceUniforms& uniforms [[ buffer(1) ]]) {
    constexpr sampler colorSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    if(uniforms.hasFaces) {
        uint count = rects.get_width();
        uint index = 0;
        while(index < count) {
            float4 x = rects.read(index);
            float4 w = rects.read(index + 2);
            float4 y = rects.read(index + 1);
            float4 h = rects.read(index + 3);
            float shouldPixel = show(in.texCoord.x, in.texCoord.y, x[0], y[0], w[0], h[0], uniforms.aspectRatio, uniforms.padding, uniforms.edge, uniforms.axis, uniforms.divider);
            if(shouldPixel <= 1.0) {
                return blurTexture.sample(colorSampler, float2(in.texCoord.y, in.texCoord.x));
            }
            index += 4;
        }
    }
    float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
    return textureColor;
}

