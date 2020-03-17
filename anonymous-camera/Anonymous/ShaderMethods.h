//
//  ShaderMethods.h
//  ShaderKit
//
//  Created by Alisdair Mills on 03/12/2019.
//  Copyright © 2019 amills. All rights reserved.
//

#ifndef ShaderMethods_h
#define ShaderMethods_h

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ImageColorInOut;

float4 ycbcrToRGBTransform(float4 y, float4 CbCr);
float2 mod(float2 x, float2 y);
float show(float inX, float inY, float x, float y, float w, float h, float aspectRatio, float padding, float edge, float axis, float divider);

#endif /* ShaderMethods_h */
