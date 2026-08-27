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
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: width))
                .overlay{ SliderThumb(color: color, width: width, height: height) }
                .background(ScrollWheelMonitor(isHovering: isHovering, storeColor: storeColor, onScroll: handleScroll))
                .onHover { isHovering = $0 }
        }
    }
    
    private struct SliderThumb: View {
        var color: HSBAColor
        let width: CGFloat
        let height: CGFloat
        var body: some View {
            Circle()
                .fill(Color(hue: color.hue, saturation: color.saturation, brightness: color.brightness))
                .stroke(Color.primary, lineWidth: 2)
                .frame(width: width + width * 0.25)
                .allowsHitTesting(false)
                .position(x: width * 0.5, y: height - color.brightness * height)
        }
    }
    
    private func handleScroll(_: CGPoint, event: NSEvent) {
        guard isHovering else { return }
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.brightness = min(max(color.brightness + delta, 0), 1)
    }
}
