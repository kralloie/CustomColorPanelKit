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
    @State private var width: CGFloat = 0
    @State private var centerLock: Bool = false
    private let snapDistance: CGFloat = 6
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            ZStack(alignment: .leading) {
                OpacitySlider(color: color)
                    .frame(width: width, height: height)
                    .background(CheckerboardView(rows: 3))
                    .clipShape(RoundedRectangle(cornerRadius: height))
                    .gesture(dragGesture)
                
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .frame(width: 2, height: height)
                    .position(x: width * 0.5, y: height * 0.5)
                
                SliderThumb(
                    orientation: .horizontal,
                    color: color.color,
                    value: color.alpha,
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
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
    }
    
    private func handleScroll(event: NSEvent) {
        let step: Double = 0.01
        let delta = event.scrollingDeltaY > 0 ? step : -step
        color.alpha = min(max(color.alpha + delta, 0), 1)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged {
                let pos = $0.location.x
                let center = width * 0.5
                
                if !gestureBegan {
                    gestureBegan = true
                    centerLock = false
                }
                
                if !centerLock && abs(pos - center) < snapDistance {
                    centerLock = true
                    color.alpha = 0.5
                } else if centerLock && abs(pos - center) < snapDistance * 2  {
                    color.alpha = 0.5
                } else {
                    color.alpha = (pos / width).clamped(to: 0...1)
                }
            }
    }
}
