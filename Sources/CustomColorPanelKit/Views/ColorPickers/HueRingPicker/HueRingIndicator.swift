//
//  HueRingIndicator.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 17/06/2026.
//

import SwiftUI

/// An arrow-shaped marker: an equilateral triangle pointing left, joined to a rectangle with rounded right corners.
///
/// Used as the hue indicator on ``HueRing``.
struct HueRingIndicator: Shape {
    /// Width of the rectangle on the trailing edge of the triangle pointing to the left.
    var rectangleWidth: CGFloat
    /// Corner radius of the trailing corners of the rectangle.
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let height = rect.height
        let triangleWidth = height * sqrt(3) / 2
        
        let x0 = rect.minX
        let x1 = x0 + triangleWidth
        let x2 = x1 + rectangleWidth
        
        let y0 = rect.minY
        let y1 = rect.maxY
        let midY = rect.midY
        
        let radius = min(cornerRadius, rectangleWidth / 2, height / 2)
        
        var path = Path()
        
        path.move(to: CGPoint(x: x0, y: midY))
        path.addLine(to: CGPoint(x: x1, y: y0))
        
        path.addLine(to: CGPoint(x: x2 - radius, y: y0))
        path.addQuadCurve(to: CGPoint(x: x2, y: y0 + radius), control: CGPoint(x: x2, y: y0))
        
        path.addLine(to: CGPoint(x: x2, y: y1 - radius))
        path.addQuadCurve(to: CGPoint(x: x2 - radius, y: y1), control: CGPoint(x: x2, y: y1))
        
        path.addLine(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x0, y: midY))
        path.closeSubpath()
        return path
    }
}
