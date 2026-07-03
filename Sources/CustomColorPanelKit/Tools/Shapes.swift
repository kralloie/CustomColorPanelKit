//
//  Shapes.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 17/06/2026.
//

import SwiftUI

struct LeftPointingTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
    }
}
