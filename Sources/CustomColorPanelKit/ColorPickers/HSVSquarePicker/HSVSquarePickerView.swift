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
    @State private var hoveringSlider: Bool = false
    private func storeColor() -> Void { colorHistory.add(color) }
    
    var body: some View {
        VStack {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let size = min(width, height)
                let hueSliderWidth = size * 0.05
                let opacitySliderHeight = hueSliderWidth
                let squareSize = min(size - hueSliderWidth, height - opacitySliderHeight)
                
                VStack(spacing: Layout.stackSpacing) {
                    HStack(spacing: Layout.stackSpacing) {
                        HSVSquare(color: $color, storeColor: storeColor)
                            .positionIndicator(squareSize: squareSize, color: color)
                            .frame(width: squareSize, height: squareSize)
                        
                        HueSlider(color: $color, storeColor: storeColor)
                            .positionIndicator(sliderWidth: hueSliderWidth, height: height - opacitySliderHeight)
                            .hueSliderScrollHandler(isHovering: hoveringSlider, color: $color, storeColor: storeColor)
                            .frame(width: hueSliderWidth, height: height - opacitySliderHeight)
                            .onHover { hoveringSlider = $0 }
                    }
                    OpacitySliderView(color: $color)
                        .frame(width: size + Layout.stackSpacing, height: opacitySliderHeight)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(Layout.outerPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(minWidth: Layout.hsvSquareMinSize, minHeight: Layout.hsvSquareMinSize)
    }
}

private extension View {
    func hueSliderScrollHandler(isHovering: Bool, color: Binding<HSBAColor>, storeColor: @escaping () -> Void) -> some View {
        background {
            ScrollWheelMonitor(isHovering: isHovering, storeColor: storeColor) { point, event in
                let delta = event.scrollingDeltaY > 0 ? 1.0 : -1.0
                color.wrappedValue.hue = max(min(color.wrappedValue.hue + (delta / 100), 1), 0)
            }
        }
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

private extension HueSlider {
    func positionIndicator (sliderWidth: CGFloat, height: CGFloat) -> some View {
        overlay(alignment: .trailing) {
            Rectangle()
                .fill(.clear)
                .frame(
                    width: sliderWidth,
                    height: 10
                )
                .overlay(alignment: .trailing) {
                    LeftPointingTriangle()
                        .fill(.primary)
                        .frame(width: 10, height: 10)
                        .shadow(radius: 2)
                        .overlay {
                            LeftPointingTriangle()
                                .fill(Color(hue: color.hue, saturation: 1, brightness: 1))
                                .frame(width: 10, height: 10)
                        }
                }
                .allowsHitTesting(false)
                .position(x: sliderWidth * 0.5 + 5, y: height - (color.hue * height))
        }
    }
}
