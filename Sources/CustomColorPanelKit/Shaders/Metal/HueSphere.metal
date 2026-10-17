//
//  HueSphere.metal
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

#include <metal_stdlib>
#include "definitions.h"
using namespace metal;


struct HueSphereVertexOut {
    float4 pos [[position]];
    float2 uv;
};

vertex HueSphereVertexOut HueSphereVertexShader(unsigned int vid [[vertex_id]]) {
    HueSphereVertexOut out;
    out.pos = float4(positions[vid], 0, 1);
    out.uv = positions[vid];
    
    return out;
}

fragment float4 HueSphereFragmentShader(HueSphereVertexOut in [[stage_in]]) {
    float magnitude = length(in.uv);
    
    float hue = fract(atan2(in.uv.y, in.uv.x) / (2.0 * M_PI_F));
    float saturation = magnitude;
    float aa = fwidth(magnitude);
    float alpha = 1 - smoothstep(1 - aa, 1.0, magnitude);

    return float4(hsbToRGB(hue, saturation, 1), alpha);
}
