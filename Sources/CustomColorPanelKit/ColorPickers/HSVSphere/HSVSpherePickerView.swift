//
//  HSVSpherePickerView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import SwiftUI

private enum Layout {
    static let hsvSphereMinSize: CGFloat = 250
    static let hsvSpherePositionIndicatorSize: CGFloat = 10
    static let outerPadding: CGFloat = 20
}

struct HSVSpherePickerView: View {
    @Binding var color: HSBAColor
    var colorHistory: ColorHistory
    
    private func storeColor() { colorHistory.add(color) }
    
    var body: some View {
        VStack {
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                let sliderHeight = size * 0.05
                let sphereSize = size - (sliderHeight * 2)
                let sphereRadius = sphereSize * 0.5
                VStack() {
                    HSVSphere(color: $color, storeColor: storeColor)
                        .positionIndicator(color: color, sphereRadius: sphereRadius)
                        .frame(width: sphereSize, height: sphereSize)
                    
                    BrightnessSliderView(color: $color, storeColor: storeColor)
                        .frame(width: size, height: sliderHeight)
                    
                    OpacitySliderView(color: $color)
                        .frame(width: size, height: sliderHeight)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(Layout.outerPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(minWidth: Layout.hsvSphereMinSize, minHeight: Layout.hsvSphereMinSize)
    }
}

private extension HSVSphere {
    func positionIndicator(color: HSBAColor, sphereRadius: CGFloat) -> some View {
        overlay {
            Circle()
                .fill(Color(hue: color.hue, saturation: color.saturation, brightness: 1))
                .stroke(.black)
                .frame(width: Layout.hsvSpherePositionIndicatorSize)
                .offset(
                    x: sphereRadius * cos(color.hue * 2 * .pi) * color.saturation,
                    y: -(sphereRadius * sin (color.hue * 2 * .pi)) * color.saturation
                )
        }
    }
}
