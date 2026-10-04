//
//  SliderThumb.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 03/09/2026.
//

import SwiftUI

/// A circular indicator that represents the current position in a slider determined by the component value.
struct SliderThumb: View {
    /// Whether the slider is vertical or horizontal.
    let orientation: SliderOrientation
    /// The current color used to fill the cursor when dragging and the preview.
    let color: Color
    /// The color the thumb shows: a dot on the white thumb at rest, and the glass tint while pressed.
    let value: CGFloat
    /// Whether this view is currently being pressed.
    let isPressed: Bool
    /// The width of the slider.
    let width: CGFloat
    /// The height of the slider.
    let height: CGFloat
    /// The thickness of the slider, if horizontal the thickness is `height`, and if vertical, the thickness is `width`.
    var thickness: CGFloat { orientation == .horizontal ? height : width }
    
    var body: some View {
        Circle()
            .fill(isPressed ? .clear : .white)
            .overlay {
                if !isPressed {
                    Circle()
                        .fill(color)
                        .frame(width: thickness * 0.6, height: thickness * 0.6)
                        .shadow(color: .black, radius: 1)
                }
            }
            .glassEffect(isPressed ? .regular.tint(color) : .identity)
            .frame(width: thickness, height: thickness)
            .scaleEffect(isPressed ? 1.25 : 1)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .offset(
                x: orientation == .horizontal ? (width - thickness) * (value - 0.5) : 0,
                y: orientation == .vertical ? (height - thickness) * -(value - 0.5) : 0
            )
            .shadow(color: .black, radius: 1)
    }
    
    /// The axis a slider runs along.
    enum SliderOrientation {
        case horizontal, vertical
    }
}
