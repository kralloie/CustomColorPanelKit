//
//  definitions.h
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

#pragma once

using namespace metal;

static constant float2 positions[4] {
    { -1, -1 },
    {  1, -1 },
    { -1,  1 },
    {  1,  1 }
};

static inline float3 hsbToRGB(float h, float s, float b) {
    h = fract(h);
    float3 rgb = clamp(
        abs(fmod(h * 6.0 + float3(0, 4, 2), 6.0) - 3.0) - 1.0,
        0.0, 1.0
    );
    return b * mix(float3(1.0), rgb, s);
}
