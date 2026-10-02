//
//  SliderThumb.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 03/09/2026.
//

import SwiftUI

struct SliderThumb: View {
    let orientation: SliderOrientation
    let color: Color
    let value: CGFloat
    let isPressed: Bool
    let width: CGFloat
    let height: CGFloat
    var size: CGFloat { orientation == .horizontal ? height : width }
    
    var body: some View {
        Circle()
            .fill(isPressed ? .clear : .white)
            .overlay {
                if !isPressed {
                    Circle()
                        .fill(color)
                        .frame(width: size * 0.6, height: size * 0.6)
                        .shadow(color: .black, radius: 1)
                }
            }
            .glassEffect(isPressed ? .regular.tint(color) : .identity)
            .frame(width: size, height: size)
            .scaleEffect(isPressed ? 1.25 : 1)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .offset(
                x: orientation == .horizontal ? (width - size) * (value - 0.5) : 0,
                y: orientation == .vertical ? (height - size) * -(value - 0.5) : 0
            )
            .shadow(color: .black, radius: 1)
    }
    
    enum SliderOrientation {
        case horizontal, vertical
    }
}
