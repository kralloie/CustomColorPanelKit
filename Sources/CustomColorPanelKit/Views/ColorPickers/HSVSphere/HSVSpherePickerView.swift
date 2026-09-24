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
    static let stackSpacing: CGFloat = 10
}

struct HSVSpherePickerView: View {
    @Binding var color: HSBAColor
    var colorHistory: ColorHistory
    
    private func storeColor() { colorHistory.add(color) }
    
    var body: some View {
        VStack {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let size = min(width, height)
                let sliderThickness = size * 0.03
                let sphereSize = min(width - sliderThickness, height - sliderThickness)
                let sphereRadius = sphereSize * 0.5
                
                VStack(alignment: .leading, spacing: Layout.stackSpacing) {
                    HStack(spacing: Layout.stackSpacing) {
                        
                        HSVSphere(color: $color, storeColor: storeColor)
                            .positionIndicator(color: color, sphereRadius: sphereRadius)
                            .frame(width: sphereSize, height: sphereSize)
                        
                        BrightnessSliderView(color: $color, storeColor: storeColor)
                            .frame(width: sliderThickness, height: sphereSize)
                    }
                    
                    OpacitySliderView(color: $color)
                        .frame(width: sphereSize, height: sliderThickness)
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
