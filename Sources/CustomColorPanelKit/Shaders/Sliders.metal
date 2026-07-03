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
    float3 rgb [[flat]];
    float4 position [[position]];
    float opacity;
};

vertex OpacitySliderVertexOut OpacitySliderVertexShader(unsigned int vid [[vertex_id]], constant float3 &hsb [[buffer(0)]]) {
    OpacitySliderVertexOut out;
    out.rgb = hsbToRGB(hsb.x, hsb.y, hsb.z);
    out.position = float4(positions[vid], 0, 1);
    out.opacity = (vid + 1) % 2;
    return out;
}

fragment float4 OpacitySliderFragmentShader(OpacitySliderVertexOut in [[stage_in]]) {
    return float4(in.rgb, in.opacity);
}
