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
            let width = geo.size.width
            OpacitySlider(color: $color, width: width)
                .frame(width: width, height: 20)
                .overlay {
                    Rectangle()
                        .fill(.thickMaterial)
                        .frame(width: 2, height: 20)
                    
                    Rectangle()
                        .stroke(.thickMaterial, lineWidth: 1)
                    
                    positionIndicator(position: width - (color.alpha * width))
                }
                .background(ScrollWheelMonitor(onScroll: handleScroll))
                .background(CheckerboardView())
                .onHover { isHovering = $0 }
        }
        .frame(height: 25)
    }
    
    private func handleScroll(_: CGPoint, event: NSEvent) {
        guard isHovering else { return }
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.alpha = min(max(color.alpha + delta, 0), 1)
    }
    
    private struct positionIndicator: View {
        let position: CGFloat
        
        var body: some View {
            LeftPointingTriangle()
                .fill(.primary)
                .frame(width: 10, height: 10)
                .rotationEffect(Angle(degrees: 270))
                .shadow(radius: 2)
                .position(x: position)
                .allowsHitTesting(false)
        }
    }
}
