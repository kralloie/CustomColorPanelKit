//
//  OpacitySliderView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 28/06/2026.
//

import SwiftUI

struct OpacitySliderView: View {
    @Binding var color: HSBAColor
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let OSIndicatorPosition = width - (color.alpha * width)
            OpacitySlider(color: $color, width: width)
                .frame(width: width, height: 20)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(.gray.opacity(0.2), lineWidth: 1)
                }
                .background(CheckerboardView())
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(alignment: .topLeading) {
                    LeftPointingTriangle()
                        .fill(.primary)
                        .frame(width: 10, height: 10)
                        .rotationEffect(Angle(degrees: 270))
                        .shadow(radius: 2)
                        .position(x: OSIndicatorPosition)
                        .allowsHitTesting(false)
                }
        }
        .frame(height: 25)
    }
}
