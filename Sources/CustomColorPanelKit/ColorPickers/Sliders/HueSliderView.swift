//
//  HueSliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 27/08/2026.
//

import SwiftUI

struct HueSliderView: View {
    @Environment(\.scrollWheelRouter) private var scrollWheelRouter
    @Binding var color: HSBAColor
    @State private var isDragging: Bool = false
    var storeColor: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            HueSlider(color: $color, isDragging: $isDragging, storeColor: storeColor)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: width))
                .overlay {
                    SliderThumb(
                        orientation: .vertical,
                        color: Color(hue: color.hue, saturation: 1, brightness: 1),
                        value: color.hue,
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
        color.hue = min(max(color.hue + delta, 0), 1)
    }
}
