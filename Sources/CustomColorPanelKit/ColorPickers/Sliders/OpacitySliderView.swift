//
//  OpacitySliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

import SwiftUI

struct OpacitySliderView: View {
    @Environment(\.scrollWheelRouter) private var scrollWheelRouter
    @Binding var color: HSBAColor
    @State var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width
            OpacitySlider(color: $color, isDragging: $isDragging)
                .frame(width: width, height: height)
                .background(CheckerboardView(rows: 3))
                .clipShape(RoundedRectangle(cornerRadius: height))
                .overlay {
                    Rectangle()
                        .fill(.thickMaterial)
                        .frame(width: 2, height: height)
                    SliderThumb(
                        orientation: .horizontal,
                        color: color.color,
                        value: color.alpha,
                        isDragging: isDragging,
                        width: width,
                        height: height
                    )
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
        color.alpha = min(max(color.alpha + delta, 0), 1)
    }
}
