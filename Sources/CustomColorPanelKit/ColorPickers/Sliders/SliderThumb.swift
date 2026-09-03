//
//  SliderThumb.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 03/09/2026.
//

import SwiftUI

struct SliderThumb: View {
    let orientation: SliderOrientation
    let color: Color
    let value: CGFloat
    let isDragging: Bool
    let width: CGFloat
    let height: CGFloat
    var size: CGFloat { orientation == .horizontal ? height + height * 0.25 : width + width * 0.25 }
    
    var body: some View {
        Circle()
            .fill(color)
            .stroke(Color.primary, lineWidth: 2)
            .background { CheckerboardView(rows: 3).clipShape(.circle) }
            .frame(width: size, height: size)
            .scaleEffect(isDragging ? 1.15 : 1)
            .position(
                x: width * (orientation == .horizontal ? value : 0.5),
                y: height - height * (orientation == .vertical ? value : 0.5)
            )
            .allowsHitTesting(false)
    }
    
    enum SliderOrientation {
        case vertical, horizontal
    }
}
