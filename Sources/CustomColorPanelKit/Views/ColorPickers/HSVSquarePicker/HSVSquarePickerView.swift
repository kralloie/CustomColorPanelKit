//
//  HSVSquarePickerView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 03/08/2026.
//

import SwiftUI

/// Layout values for ``HSVSquarePickerView``.
private enum Layout {
    static let hsvSquareMinSize: CGFloat = 250
    static let stackSpacing: CGFloat = 10
    static let outerPadding: CGFloat = 20
}

/// A color picker with an HSV Square, a vertical hue slider and an opacity slider below.
///
/// - Dragging inside the HSV Square sets the saturation and brightness.
/// - Dragging on the vertical slider sets the hue.
/// - Dragging on the horizontal slider below sets the opacity.
struct HSVSquarePickerView: View {
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// The object storing and managing previously selected colors through the picker session.
    let colorHistory: ColorHistory
    
    /// Stores the current color in the history
    ///
    /// Passed to the subviews as a closure, so they can commit a color without needing to know about the ``ColorHistory`` object.
    private func storeColor() { colorHistory.add(color) }
    
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
                        
                        VerticalSlider(
                            slider: HueSlider(),
                            value: $color.hue,
                            thumbTint: Color(hue: color.hue, saturation: 1, brightness: 1),
                            storeColor: storeColor
                        )
                            .frame(width: sliderThickness, height: squareSize)
                    }
                    OpacitySliderView(color: $color, storeColor: storeColor)
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
