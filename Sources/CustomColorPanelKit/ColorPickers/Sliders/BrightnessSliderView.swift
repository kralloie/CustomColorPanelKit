//
//  BrightnessSliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import SwiftUI

struct BrightnessSliderView: View {
    @Environment(\.scrollWheelRouter) private var scrollWheelRouter
    @Binding var color: HSBAColor
    @State private var isDragging: Bool = false
    var storeColor: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            BrightnessSlider(color: $color, isDragging: $isDragging, storeColor: storeColor)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: width))
                .overlay {
                    SliderThumb(
                        orientation: .vertical,
                        color: Color(hue: color.hue, saturation: color.saturation, brightness: color.brightness),
                        value: color.brightness,
                        isDragging: isDragging,
                        width: width,
                        height: height
                    )
                }
                .background {
                    RoundedRectangle(cornerRadius: width)
                        .fill(.tertiary)
                        .frame(width: width + 2, height: height + 2)
                }
                .onHover { isHovering in
                    if isHovering {
                        scrollWheelRouter.scrollHandler = handleScroll
                    } else {
                        scrollWheelRouter.scrollHandler = nil
                    }
                }
        }
    }
    
    private func handleScroll(event: NSEvent) {
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.brightness = min(max(color.brightness + delta, 0), 1)
    }
}
