//
//  HSVSquarePicker.metal
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 31/07/2026.
//
#include <metal_stdlib>
#include "definitions.h"
using namespace metal;

struct HSVSquareVertexOut {
    float4 pos [[position]];
    float brightness;
    float saturation;
};

struct HueSliderVertexOut {
    float4 pos [[position]];
    float hue;
};

vertex HSVSquareVertexOut HSVSquareVertexShader(unsigned int vid [[vertex_id]]) {
    HSVSquareVertexOut out;
    out.pos = float4(positions[vid], 0, 1);
    out.brightness = (out.pos.y + 1.0) * 0.5;
    out.saturation = (out.pos.x + 1.0) * 0.5;
    return out;
}

fragment float4 HSVSquareFragmentShader(HSVSquareVertexOut in [[stage_in]], constant float &hue [[buffer(0)]]) {
    return float4(hsbToRGB(hue, in.saturation, in.brightness), 1);
}

vertex HueSliderVertexOut HueSliderVertexShader(unsigned int vid [[vertex_id]]) {
    HueSliderVertexOut out;
    out.pos = float4(positions[vid], 0, 1);
    out.hue = (out.pos.y + 1.0) * 0.5;
    return out;
}

fragment float4 HueSliderFragmentShader(HueSliderVertexOut in [[stage_in]]) {
    return float4(hsbToRGB(in.hue, 1, 1), 1);
}
