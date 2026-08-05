//
//  HSVSphere.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

#include <metal_stdlib>
#include "definitions.h"
using namespace metal;


struct HSVSphereVertexOut {
    float4 pos [[position]];
    float2 uv;
};

vertex HSVSphereVertexOut HSVSphereVertexShader(unsigned int vid [[vertex_id]]) {
    HSVSphereVertexOut out;
    out.pos = float4(positions[vid], 0, 1);
    out.uv = positions[vid];
    
    return out;
}

fragment float4 HSVSphereFragmentShader(HSVSphereVertexOut in [[stage_in]], constant float &antialiasing [[buffer(0)]]) {
    float magnitude = length(in.uv);
    
    if (magnitude > 1) discard_fragment();
    
    float hue = fract(atan2(in.uv.y, in.uv.x) / (2.0 * M_PI_F));
    float saturation = magnitude;
    float alpha = 1 - smoothstep(0.99, 1.0, magnitude) * antialiasing;

    return float4(hsbToRGB(hue, saturation, 1), alpha);
}
