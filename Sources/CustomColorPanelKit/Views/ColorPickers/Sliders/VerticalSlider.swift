//
//  VerticalSlider.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 01/10/2026.
//

import SwiftUI

struct VerticalSlider<Content: View>: View {
    var slider: Content
    @Binding var value: CGFloat
    var thumbTint: Color
    
    private var scrollWheelRouter = ScrollWheelRouter.shared
    @GestureState private var isDragging: Bool = false
    @State private var size: CGSize = .zero
    @State private var gestureBegan: Bool = false
    @State private var valueAnimation: Task<Void, Never>? = nil
    var storeColor: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                slider
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: geo.size.width))
                
                SliderThumb(
                    orientation: .vertical,
                    color: thumbTint,
                    value: value,
                    isPressed: isDragging,
                    width: geo.size.width,
                    height: geo.size.height
                )
            }
            .gesture(dragGesture)
            .onHover { isHovering in
                if isHovering {
                    scrollWheelRouter.scrollHandler = handleScroll
                } else {
                    scrollWheelRouter.scrollHandler = nil
                }
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
    }
    
    private func handleScroll(event: NSEvent) -> Bool {
        valueAnimation?.cancel()
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        value = min(max(value + delta, 0), 1)
        return true
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged {
                let isFirst = !gestureBegan
                if !gestureBegan { gestureBegan = true }
                let travel = size.height - size.width
                let target = 1 - (($0.location.y - size.width * 0.5) / travel).clamped(to: 0...1)
                
                if isFirst {
                    animateValue($value, to: target, valueAnimation: $valueAnimation)
                } else {
                    valueAnimation?.cancel()
                    value = target
                }
            }
            .onEnded { _ in
                gestureBegan = false
                Task { @MainActor in
                    await valueAnimation?.value
                    storeColor()
                }
            }
    }
}
