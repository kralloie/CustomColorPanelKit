//
//  OpacitySliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

import SwiftUI

/// An opacity slider with a checkerboard pattern background.
struct OpacitySliderView: View {
    /// The scroll router instance to pass the scroll handler to.
    @Environment(ScrollWheelRouter.self) private var scrollWheelRouter
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// Whether the slider is being dragged, updated by the `dragGesture`.
    @GestureState var isDragging: Bool = false
    /// Whether the current drag has already reported its first change, so only the press animates.
    @State private var gestureBegan: Bool = false
    /// The size reported by the `onGeometryChange`.
    @State private var size: CGSize = .zero
    /// Whether the dragging should be affected by the center locking.
    @State private var centerLock: Bool = false
    /// The task running the animation that starts when the slider is pressed.
    @State private var alphaAnimation: Task<Void, Never>?
    /// The distance threshold used for entering and exiting the center lock.
    private let snapDistance: CGFloat = 6
    /// Called after the drag gesture ends to store the color to the history.
    var storeColor: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                OpacitySlider(color: color)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .background {
                        CheckerboardView(rows: 3)
                            .clipShape(RoundedRectangle(cornerRadius: geo.size.width).inset(by: 0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: geo.size.width))
                
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .frame(width: 2, height: geo.size.height)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                
                SliderThumb(
                    orientation: .horizontal,
                    color: color.color,
                    value: color.alpha,
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
            .onDisappear { scrollWheelRouter.scrollHandler = nil }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        }
    }
    
    /// The handler passed to ``scrollWheelRouter`` to be called when a scroll is detected while the cursor is hovering the slider.
    ///
    /// Positive delta Y increases the opacity by 1% and negative delta Y decreases it by 1%.
    ///
    /// - Returns: `true` if the result should be stored to the color history, `false` if it shouldn't.
    ///
    /// - Parameter event: The event containing the information of the scroll.
    private func handleScroll(event: NSEvent) -> Bool {
        alphaAnimation?.cancel()
        guard event.scrollingDeltaY != 0 else { return false }
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.alpha = min(max(color.alpha + delta, 0), 1)
        return true
    }
    
    /// Returns the alpha value based on the position inside the slider.
    ///
    /// - Parameter pos: The position inside the slider.
    private func targetAlpha(at pos: CGFloat) -> CGFloat {
        let travel = size.width - size.height
        let center = size.width * 0.5
        
        if !centerLock && abs(pos - center) < snapDistance {
            centerLock = true
            return 0.5
        } else if centerLock && abs(pos - center) < snapDistance * 2  {
            return 0.5
        } else {
            centerLock = false
            return ((pos - size.height * 0.5) / travel).clamped(to: 0...1)
        }
    }
    
    /// The gesture that handles dragging inside the Opacity Slider.
    ///
    /// The pointer is clamped when it leaves the slider shape.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged {
                guard size.width > 0 && size.width > size.height else { return }
                
                let isFirst = !gestureBegan
                
                if !gestureBegan {
                    gestureBegan = true
                    centerLock = false
                }
                
                let target = targetAlpha(at: $0.location.x)
                
                if isFirst {
                    animateValue($color.alpha, to: target, valueAnimation: $alphaAnimation)
                } else {
                    alphaAnimation?.cancel()
                    color.alpha = target
                }
            }
            .onEnded { _ in
                gestureBegan = false
                Task { @MainActor in
                    await alphaAnimation?.value
                    storeColor()
                }

            }
    }
}
