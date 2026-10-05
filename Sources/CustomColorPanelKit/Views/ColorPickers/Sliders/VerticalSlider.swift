//
//  VerticalSlider.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 01/10/2026.
//

import SwiftUI

/// A view that hosts a Metal-rendered vertical slider.
struct VerticalSlider<Content: View>: View {
    /// The Metal-rendered slider that this view hosts.
    var slider: Content
    /// A binding to the value that the slider controls.
    @Binding var value: CGFloat
    /// The color used to tint the ``SliderThumb`` glass when dragging and its color preview.
    var thumbTint: Color
    
    /// The shared scroll router instance to pass the scroll handler to.
    private var scrollWheelRouter = ScrollWheelRouter.shared
    /// Whether the slider is being dragged, updated by the `dragGesture`.
    @GestureState private var isDragging: Bool = false
    /// The size reported by the `onGeometryChange`.
    @State private var size: CGSize = .zero
    /// Whether the current drag has already reported its first change, so only the press animates.
    @State private var gestureBegan: Bool = false
    /// The task running the animation that starts when the slider is pressed.
    @State private var valueAnimation: Task<Void, Never>? = nil
    /// Called after the drag gesture ends to store the color to the history.
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
    
    /// The handler passed to ``scrollWheelRouter`` to be called when a scroll is detected while the cursor is hovering the slider.
    ///
    /// Positive delta Y increases the value by 1% and negative delta Y decreases it by 1%.
    ///
    /// - Returns: `true` if the result should be stored to the color history, `false` if it shouldn't.
    ///
    /// - Parameter event: The event containing the information of the scroll.
    private func handleScroll(event: NSEvent) -> Bool {
        valueAnimation?.cancel()
        guard event.scrollingDeltaY != 0 else { return false }
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        value = min(max(value + delta, 0), 1)
        return true
    }
    
    /// The gesture that handles dragging inside the slider.
    ///
    /// The pointer is clamped when it leaves the slider shape.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged {
                guard size.height > 0 && size.height > size.width else { return }
                
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
