//
//  BodyPixelShader.metal
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

fragment float4 colorFillBodyFragment(ImageColorInOut in [[stage_in]],
                            texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]],
                            texture2d<float, access::sample> alphaTexture [[ texture(3) ]],
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
        return float4(uniforms.red, uniforms.green, uniforms.blue, 1);
    }
    if(uniforms.invert == 1.0) {
        return float4(uniforms.red, uniforms.green, uniforms.blue, 1);
    }
    float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
    return textureColor;
}

fragment float4 bwNoiseBodyFragment(ImageColorInOut in [[stage_in]],
                            texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]],
                            texture2d<float, access::sample> alphaTexture [[ texture(3) ]],
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
        Loki rng = Loki((in.texCoord.x * uniforms.imgWidth) + 1, (in.texCoord.y * uniforms.imgHeight) + 1, uniforms.iteration + 1);
        float random = rng.rand();
        return float4(random, random, random, 1);
    }
    if(uniforms.invert == 1.0) {
        Loki rng = Loki((in.texCoord.x * uniforms.imgWidth) + 1, (in.texCoord.y * uniforms.imgHeight) + 1, uniforms.iteration + 1);
        float random = rng.rand();
        return float4(random, random, random, 1);
    }
    float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
    return textureColor;
}

fragment float4 colorNoiseBodyFragment(ImageColorInOut in [[stage_in]],
                            texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]],
                            texture2d<float, access::sample> alphaTexture [[ texture(3) ]],
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
        Loki rng = Loki((in.texCoord.x * uniforms.imgWidth) + 1, (in.texCoord.y * uniforms.imgHeight) + 1, uniforms.iteration + 1);
        float random_r = rng.rand();
        float random_g = rng.rand();
        float random_b = rng.rand();
        return float4(random_r, random_g, random_b, 1);
    }
    if(uniforms.invert == 1.0) {
        Loki rng = Loki((in.texCoord.x * uniforms.imgWidth) + 1, (in.texCoord.y * uniforms.imgHeight) + 1, uniforms.iteration + 1);
        float random_r = rng.rand();
        float random_g = rng.rand();
        float random_b = rng.rand();
        return float4(random_r, random_g, random_b, 1);
    }
    float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
    return textureColor;
}

fragment float4 bodyPixellateFragment(ImageColorInOut in [[stage_in]],
                            texture2d<float, access::sample> capturedImageTextureY [[ texture(1) ]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(2) ]],
                            texture2d<float, access::sample> alphaTexture [[ texture(3) ]],
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
        float2 sampleDivisor = float2(uniforms.widthOfPixel / uniforms.aspectRatio, uniforms.widthOfPixel);
        float2 samplePos = in.texCoord - mod(in.texCoord, sampleDivisor) + float2(0.5) * sampleDivisor;
        float4 pixellateColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, samplePos), capturedImageTextureCbCr.sample(colorSampler, samplePos));
        return pixellateColor;
    }
    if(uniforms.invert == 1.0) {
        float2 sampleDivisor = float2(uniforms.widthOfPixel / uniforms.aspectRatio, uniforms.widthOfPixel);
        float2 samplePos = in.texCoord - mod(in.texCoord, sampleDivisor) + float2(0.5) * sampleDivisor;
        float4 pixellateColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, samplePos), capturedImageTextureCbCr.sample(colorSampler, samplePos));
        return pixellateColor;
    }
    float4 textureColor = ycbcrToRGBTransform(capturedImageTextureY.sample(colorSampler, in.texCoord), capturedImageTextureCbCr.sample(colorSampler, in.texCoord));
    return textureColor;
}
