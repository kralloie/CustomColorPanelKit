//
//  HueSliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 27/08/2026.
//

import SwiftUI

struct HueSliderView: View {
    private var scrollWheelRouter = ScrollWheelRouter.shared
    @Binding var color: HSBAColor
    @GestureState private var isDragging: Bool = false
    @State private var height: CGFloat = 0
    var storeColor: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                HueSlider(color: color)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: width))
                    .gesture(dragGesture)
                
                SliderThumb(
                    orientation: .vertical,
                    color: Color(hue: color.hue, saturation: 1, brightness: 1),
                    value: color.hue,
                    isDragging: isDragging,
                    width: width,
                    height: height
                )
                .gesture(dragGesture)
            }
            .onHover { isHovering in
                if isHovering {
                    scrollWheelRouter.scrollHandler = handleScroll
                } else {
                    scrollWheelRouter.scrollHandler = nil
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
    }
    
    private func handleScroll(event: NSEvent) {
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.hue = min(max(color.hue + delta, 0), 1)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged {
                color.hue = 1 - ($0.location.y / height).clamped(to: 0...1)
            }
            .onEnded { _ in storeColor() }
    }
}
