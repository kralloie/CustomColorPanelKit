//
//  Shaders.metal
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 05/06/2026.
//

#include <metal_stdlib>
#include "definitions.h"
using namespace metal;

#pragma mark - Hue Ring Pipeline

struct HueRingVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex HueRingVertexOut HueRingVertexShader(unsigned int vid [[vertex_id]]) {
    HueRingVertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.uv = positions[vid];
    return out;
}

fragment float4 HueRingFragmentShader(HueRingVertexOut in [[stage_in]]) {
    float2 uv = in.uv;
    float dist = length(uv);
    
    float hue = fract(atan2(uv.y, uv.x) / (2.0 * M_PI_F));
    
    float3 color = hsbToRGB(hue, 1.0, 1.0);
    float aa = fwidth(dist);
    float outerAlpha = 1.0 - smoothstep(1.0 - aa, 1.0, dist);
    float innerAlpha = smoothstep(0.76 - aa, 0.76, dist);
    return float4(color, outerAlpha * innerAlpha);
}

#pragma mark - HSB Triangle Pipeline

struct HSBTriangleVertexOut {
    float4 position [[position]];
    float3 colorRGB;
    float3 barycentric;
};

vertex HSBTriangleVertexOut HSBTriangleVertexShader(unsigned int vid[[vertex_id]], constant float &hue [[buffer(0)]], constant bool &hueRotation [[buffer(1)]]) {
    float hueAngle = select(M_PI_F * 0.5, hue * 2 * M_PI_F, hueRotation);
    float vertexAngle = hueAngle + (2 * M_PI_F / 3) * vid;
    float2 pos = float2(cos(vertexAngle), sin(vertexAngle));
    
    HSBTriangleVertexOut out;
    out.position = float4(pos, 0, 1);
    out.barycentric = { 0, 0, 0 };
    out.barycentric[vid] = 1;
    out.colorRGB = hsbToRGB(hue, 1.0, 1.0);
    
    return out;
}

fragment float4 HSBTriangleFragmentShader(HSBTriangleVertexOut in [[stage_in]]) {
    float minBarycentric = min(in.barycentric.x, min(in.barycentric.y, in.barycentric.z));
    float aa = fwidth(minBarycentric);
    float alpha = smoothstep(0.00 - aa, 0.01, minBarycentric);
    float3 rgb = in.barycentric.x * in.colorRGB
               + in.barycentric.y * float3(0, 0, 0)
               + in.barycentric.z * float3(1, 1, 1);
    return float4(rgb, alpha);
}

#pragma mark - Color Example Pipeline

float3 barycentric(float x, float y) {
    const float u = (1.0f - y) * 0.5f;
    const float v = (y - x) * 0.5f;
    const float w = (1.0f + x) * 0.5f;
    return { u, v, w };
}

constant float kEpsilon = 1e-5f;

bool insideTriangle(float x, float y) {
    float3 bc = barycentric(x, y);
    return bc.x >= -kEpsilon && bc.y >= -kEpsilon && bc.z >= -kEpsilon;
}

struct ColorExampleVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex ColorExampleVertexOut ColorExampleVertexShader(unsigned int vid [[vertex_id]]) {
    ColorExampleVertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.uv = positions[vid];
    
    return out;
}

fragment float4 ColorExampleFragmentShader(ColorExampleVertexOut in [[stage_in]], constant float4 &hsba [[buffer(0)]]) {
    float3 rgb = hsbToRGB(hsba.x, hsba.y, hsba.z);
    float isInside = float(insideTriangle(in.uv.x, in.uv.y));
    float alpha = (1.0 * isInside) + (hsba.w * !isInside);
    
    return float4(rgb.x, rgb.y, rgb.z, alpha);
}
