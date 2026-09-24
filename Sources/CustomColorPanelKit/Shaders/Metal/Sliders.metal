//
//  Sliders.metal
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

#include <metal_stdlib>
#include "definitions.h"
using namespace metal;

struct OpacitySliderVertexOut {
    float4 position [[position]];
    float opacity;
};

vertex OpacitySliderVertexOut OpacitySliderVertexShader(unsigned int vid [[vertex_id]]) {
    OpacitySliderVertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.opacity = (1.0 + positions[vid].x) * 0.5;
    return out;
}

fragment float4 OpacitySliderFragmentShader(OpacitySliderVertexOut in [[stage_in]], constant float3 &rgb [[buffer(0)]]) {
    return float4(rgb, in.opacity);
}


struct BrightnessSliderVertexOut {
    float4 position [[position]];
    float brightness;
};

vertex BrightnessSliderVertexOut BrightnessSliderVertexShader(unsigned int vid [[vertex_id]]) {
    BrightnessSliderVertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.brightness = ( positions[vid].y + 1) * 0.5;
    return out;
}

fragment float4 BrightnessSliderFragmentShader(BrightnessSliderVertexOut in [[stage_in]], constant float2 &hueSaturation [[buffer(0)]]) {
    return float4(hsbToRGB(hueSaturation.x, hueSaturation.y, 1) * in.brightness, 1);
}
