//
//  BodyBlurShader.metal
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

fragment float4 bodyBlurFragment(ImageColorInOut in [[stage_in]],
                            texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]],
                            texture2d<float, access::sample> alphaTexture [[ texture(3) ]],
                            texture2d<float, access::sample> blurTexture [[ texture(4) ]],
                            constant BodyUniforms& uniforms [[ buffer(1) ]]) {
    
    constexpr sampler colorSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    float4 a = alphaTexture.sample(colorSampler, in.texCoord);
    float redVal = a.r;
    if(uniforms.padding > 0.0 && redVal != 1.0) {
        float angle = 0.0;
        while(angle < 360.0) {
            float bearing = angle * (M_PI_F / 180.0);
            float x = in.texCoord.x + (uniforms.padding * cos(bearing));
            float y = in.texCoord.y + (uniforms.padding * sin(bearing));
            a = alphaTexture.sample(colorSampler, float2(x, y));
            if(a.r == 1.0) { redVal = 1.0; }
            angle += 60;
        }
    }
    if(uniforms.divider > 0.0 && redVal == 1.0) {
        if(uniforms.axis == 2.0) { if(uniforms.edge == 0.0) { if(in.texCoord.x <= uniforms.divider) { redVal = 0.0; } }
        else { if(in.texCoord.x >= uniforms.divider) { redVal = 0.0; } } }
        else if(uniforms.axis == 3.0) { if(uniforms.edge == 0.0) { if(in.texCoord.x >= uniforms.divider) { redVal = 0.0; } }
        else { if(in.texCoord.x <= uniforms.divider) { redVal = 0.0; } } }
    }
    if(redVal == 1.0) {
        if(uniforms.invert == 1.0) {
            float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
            return textureColor;
        }
        return blurTexture.sample(colorSampler, float2(1.0 - in.texCoord.y, in.texCoord.x));
    }
    if(uniforms.invert == 1.0) {
        return blurTexture.sample(colorSampler, float2(1.0 - in.texCoord.y, in.texCoord.x));
    }
    float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
    return textureColor;
}


