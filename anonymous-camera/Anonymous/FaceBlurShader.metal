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

kernel void faceBlurCompute(texture2d<float, access::read> source [[ texture(0) ]],
                        texture2d<float, access::read> blur [[ texture(1) ]],
                        texture2d<float, access::write> dest [[ texture(2) ]],
                        texture1d<float, access::read> rects [[ texture(3) ]],
                        uint2 gid [[ thread_position_in_grid ]],
                        constant FaceUniforms& uniforms [[ buffer(1) ]]) {
    
    if(uniforms.hasFaces) {
        float width = source.get_width();
        float height = source.get_height();
        uint count = rects.get_width();
        uint index = 0;
        while(index < count) {
            float4 x = rects.read(index);
            float4 w = rects.read(index + 2);
            float4 y = rects.read(index + 1);
            float4 h = rects.read(index + 3);
            float inX = 1.0 - (gid[0] / width);
            float inY = gid[1] / height;
            float shouldPixel = show(inX, inY, x[0], y[0], w[0], h[0], uniforms.aspectRatio, uniforms.padding, uniforms.edge, uniforms.axis, uniforms.divider);
            if(shouldPixel <= 1.0) {
                float4 col = blur.read(gid);
                dest.write(col, gid);
            }
            index += 4;
        }
    }
}


