//
//  BrightnessSliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import SwiftUI

struct BrightnessSliderView: View {
    @Binding var color: HSBAColor
    @State private var isHovering: Bool = false
    var storeColor: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            BrightnessSlider(color: $color, storeColor: storeColor)
                .positionIndicator(sliderWidth: width, height: height)
                .frame(width: width, height: height)
                .background(ScrollWheelMonitor(isHovering: isHovering, storeColor: storeColor, onScroll: handleScroll))
                .onHover { isHovering = $0 }
        }
    }
    
    private func handleScroll(_: CGPoint, event: NSEvent) {
        guard isHovering else { return }
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.brightness = min(max(color.brightness + delta, 0), 1)
    }
}

private extension BrightnessSlider {
    func positionIndicator(sliderWidth: CGFloat, height: CGFloat) -> some View {
        overlay(alignment: .trailing) {
            Rectangle()
                .fill(.clear)
                .frame(width: sliderWidth, height: 10)
                .overlay(alignment:.trailing) {
                    LeftPointingTriangle()
                        .fill(.primary)
                        .frame(width: 10, height: 10)
                }
                .allowsHitTesting(false)
                .position(x: sliderWidth * 0.5 + 5, y: height - color.brightness * height)
        }
    }
}
