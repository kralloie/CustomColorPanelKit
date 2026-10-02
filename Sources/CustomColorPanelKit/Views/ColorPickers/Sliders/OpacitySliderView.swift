//
//  OpacitySliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

import SwiftUI

struct OpacitySliderView: View {
    private var scrollWheelRouter = ScrollWheelRouter.shared
    @Binding var color: HSBAColor
    @GestureState var isDragging: Bool = false
    @State private var gestureBegan: Bool = false
    @State private var size: CGSize = .zero
    @State private var centerLock: Bool = false
    @State private var alphaAnimation: Task<Void, Never>?
    private let snapDistance: CGFloat = 6

    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                OpacitySlider(color: color)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .background { CheckerboardView(rows: 3) }
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
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        }
    }
    
    private func handleScroll(event: NSEvent) {
        alphaAnimation?.cancel()
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.alpha = min(max(color.alpha + delta, 0), 1)
    }
    
    private func targetAlpha(at pos: CGFloat) -> CGFloat {
        let travel = size.width - size.height
        let center = size.width * 0.5
        
        if !centerLock && abs(pos - center) < snapDistance {
            centerLock = true
            return 0.5
        } else if centerLock && abs(pos - center) < snapDistance * 2  {
            return 0.5
        } else {
            return ((pos - size.height * 0.5) / travel).clamped(to: 0...1)
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged {
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
            .onEnded { _ in gestureBegan = false }
    }
}
