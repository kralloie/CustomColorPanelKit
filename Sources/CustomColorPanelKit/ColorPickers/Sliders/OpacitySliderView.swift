//
//  OpacitySliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

import SwiftUI

struct OpacitySliderView: View {
    @Binding var color: HSBAColor
    @State private var isHovering: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width
            OpacitySlider(color: $color)
                .frame(width: width, height: height)
                .background(CheckerboardView(rows: 3))
                .clipShape(RoundedRectangle(cornerRadius: height))
                .overlay {
                    Rectangle()
                        .fill(.thickMaterial)
                        .frame(width: 2, height: height)
                    SliderThumb(color: color, width: width, height: height)
                }
                .background(ScrollWheelMonitor(isHovering: isHovering, onScroll: handleScroll))
                .onHover { isHovering = $0 }
        }
    }
    
    private struct SliderThumb: View {
        var color: HSBAColor
        let width: CGFloat
        let height: CGFloat
        var body: some View {
            Circle()
                .fill(color.color)
                .stroke(Color.primary, lineWidth: 2)
                .background { CheckerboardView(rows: 3).clipShape(.circle) }
                .frame(height: height + height * 0.25)
                .position(x: width * color.alpha, y: height * 0.5)
                .allowsHitTesting(false)
        }
    }
    
    private func handleScroll(_: CGPoint, event: NSEvent) {
        guard isHovering else { return }
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.alpha = min(max(color.alpha + delta, 0), 1)
    }
}
