//
//  HSVSquarePickerView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 03/08/2026.
//

import SwiftUI

private enum Layout {
    static let hsvSquareMinSize: CGFloat = 250
    static let hsvSquareIndicatorSize: CGFloat = 10
    static let stackSpacing: CGFloat = 10
    static let outerPadding: CGFloat = 20
}

struct HSVSquarePickerView: View {
    @Binding var color: HSBAColor
    let colorHistory: ColorHistory
    private func storeColor() -> Void { colorHistory.add(color) }
    
    var body: some View {
        VStack {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let size = min(width, height)
                let sliderThickness = size * 0.03
                let squareSize = min(size - sliderThickness, height - sliderThickness)
                
                VStack(alignment: .leading, spacing: Layout.stackSpacing) {
                    HStack(spacing: Layout.stackSpacing) {
                        HSVSquare(color: $color, storeColor: storeColor)
                            .positionIndicator(squareSize: squareSize, color: color)
                            .frame(width: squareSize, height: squareSize)
                        
                        HueSliderView(color: $color, storeColor: storeColor)
                            .frame(width: sliderThickness, height: squareSize)
                    }
                    OpacitySliderView(color: $color)
                        .frame(width: squareSize, height: sliderThickness)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(Layout.outerPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(minWidth: Layout.hsvSquareMinSize, minHeight: Layout.hsvSquareMinSize)
    }
}

private extension HSVSquare {
    func positionIndicator(squareSize: CGFloat, color: HSBAColor) -> some View {
        overlay {
            Circle()
                .fill(Color(hue: color.hue, saturation: color.saturation, brightness: color.brightness))
                .stroke(color.brightness > 0.5 ? .black : .white, lineWidth: 1)
                .frame(width: Layout.hsvSquareIndicatorSize)
                .position(x: squareSize * color.saturation, y: squareSize - squareSize * color.brightness)
        }
    }
}
