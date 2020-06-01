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

float rand(int x, int y, int z);
float4 ycbcrToRGBTransform(float4 y, float4 CbCr);
float2 mod(float2 x, float2 y);
float show(float inX, float inY, float x, float y, float w, float h, float aspectRatio, float padding, float edge, float axis, float divider);

class Loki {
private:
    thread float seed;
    unsigned TausStep(const unsigned z, const int s1, const int s2, const int s3, const unsigned M);

public:
    thread Loki(const unsigned seed1, const unsigned seed2 = 1, const unsigned seed3 = 1);

    thread float rand();
};

#endif /* ShaderMethods_h */
