//
//  Header.h
//  ShaderKit
//
//  Created by Alisdair Mills on 03/12/2019.
//  Copyright © 2019 amills. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

typedef struct {
    float aspectRatio;
    float widthOfPixel;
    float padding;
    float divider;
    float edge;
    float axis;
    float hasFaces;
} FaceUniforms;

typedef struct {
    float aspectRatio;
    float widthOfPixel;
    float divider;
    float edge;
    float axis;
    float padding;
    float invert;
} BodyUniforms;

#endif /* Header_h */
