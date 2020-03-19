//
//  FacePixelShader.metal
//  anonymous-camera
//
//  Created by Alisdair Mills on 05/12/2019.
//  Copyright © 2019 Aaron Abentheuer. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"
#import "ShaderMethods.h"
using namespace metal;

float2 mod(float2 x, float2 y) {
    return x - y * floor(x / y);
}

float show(float inX, float inY, float x, float y, float w, float h, float aspectRatio, float padding, float edge, float axis, float divider) {
    float cX = x + (w / 2.0);
    float cY = y + (h / 2.0);
    float maxSide = w;
    if(h > maxSide) { maxSide = h; }
    if (aspectRatio > 1.0) { maxSide = maxSide / aspectRatio; }
    else { maxSide = maxSide * aspectRatio; }
    float pad = padding + 0.04;
    h = maxSide + pad;
    w = maxSide + pad;
    if (aspectRatio > 1.0) { h = h * aspectRatio; }
    else { w = w / aspectRatio; }
    float p = (pow((inX - cX), 2.0) / pow((w / 2.0), 2.0)) + (pow((inY - cY), 2.0) / pow((h / 2.0), 2.0));
    if(p <= 1.0) {
        if(divider > 0.0 && aspectRatio > 1.0) {
            if(axis == 2.0) { if(edge == 0.0) { if(cX <= divider) { return 20.0; } }
            else { if(cX >= divider) { return 20.0; } } }
            else if(axis == 3.0) { if(edge == 0.0) { if(cX >= divider) { return 20.0; } }
            else { if(cX <= divider) { return 20.0; } } }
        }
        else if(divider > 0.0) {
            if(axis == 2.0) { if(edge == 0.0) { if(cY <= divider) { return 20.0; } }
            else { if(cY >= divider) { return 20.0; } } }
            else if(axis == 3.0) { if(edge == 0.0) { if(cY >= divider) { return 20.0; } }
            else { if(cY <= divider) { return 20.0; } } }
        }
        return p;
    }
    return 10.0;
}

fragment float4 pixellateFragment(ImageColorInOut in [[stage_in]],
                            texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]],
                            texture1d<float, access::read> rects [[ texture(3) ]],
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
                float2 sampleDivisor = float2(uniforms.widthOfPixel / uniforms.aspectRatio, uniforms.widthOfPixel);
                float2 samplePos = in.texCoord - mod(in.texCoord, sampleDivisor) + float2(0.5) * sampleDivisor;
                float4 pixellateColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, samplePos), capturedImageTextureCbCr.sample(colorSampler, samplePos));
                return pixellateColor;
            }
            index += 4;
        }
    }
    float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
    return textureColor;
}
