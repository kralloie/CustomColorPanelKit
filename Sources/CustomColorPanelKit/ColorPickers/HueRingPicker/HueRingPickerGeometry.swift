//
//  HueWheelGeometry.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 17/06/2026.
//

import SwiftUI

struct HueRingPickerGeometry {
    let color: HSBAColor
    let viewSize: CGSize
    let viewRadius: CGFloat
    let triangleSize: CGFloat
    let hueAngle: CGFloat
    let hueRingIndicatorSize: CGSize
    let hueRotation: Bool
    
    var hueRingIndicatorOffset: CGSize {
        CGSize(
            width: cos(hueAngle) * 0.875 * viewRadius,
            height: -sin(hueAngle) * 0.875 * viewRadius,
        )
    }
    
    var hsbTriangleIndicatorOffset: CGSize {
        let v = color.brightness
        let s = color.saturation

        let w0 = v * s
        let w1 = 1 - v
        let w2 = v * (1 - s)

        let r = triangleSize * 0.5
        let angle = hueRotation ? hueAngle : .pi * 0.5
        let offset: CGFloat = 2 * .pi / 3

        let v0 = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
        let v1 = CGPoint(x: cos(angle + offset) * r, y: sin(angle + offset) * r)
        let v2 = CGPoint(x: cos(angle + offset * 2) * r, y: sin(angle + offset * 2) * r)

        let px = w0 * v0.x + w1 * v1.x + w2 * v2.x
        let py = w0 * v0.y + w1 * v1.y + w2 * v2.y

        return CGSize(width: px, height: -py)
    }

    init(color: HSBAColor, viewSize: CGSize, hueRotation: Bool) {
        self.color = color
        self.viewSize = viewSize
        self.viewRadius = viewSize.width * 0.5
        self.triangleSize = viewRadius * 1.25
        self.hueAngle = color.hue * 2 * .pi
        self.hueRingIndicatorSize = CGSize(width: viewSize.width * 0.125, height: 1)
        self.hueRotation = hueRotation
    }
}
