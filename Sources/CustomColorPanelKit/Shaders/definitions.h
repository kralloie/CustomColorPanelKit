//
//  definitions.h
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

#pragma once

static constant float2 positions[4] {
    { -1, -1 },
    {  1, -1 },
    { -1,  1 },
    {  1,  1 }
};

static inline float3 hsbToRGB(float h, float s, float b) {
    h = metal::fract(h);
    float3 rgb = metal::clamp(
        metal::abs(metal::fmod(h * 6.0 + metal::float3(0, 4, 2), 6.0) - 3.0) - 1.0,
        0.0, 1.0
    );
    return b * metal::mix(float3(1.0), rgb, s);
}
