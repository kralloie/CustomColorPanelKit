//
//  HueSpherePickerView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/08/2026.
//

import SwiftUI


/// Layout values for ``HueSpherePickerView``.
private enum Layout {
    static let hsvSphereMinSize: CGFloat = 250
    static let outerPadding: CGFloat = 20
    static let stackSpacing: CGFloat = 10
}

/// A color picker with a Hue Sphere, a vertical brightness slider and an opacity slider below.
///
/// - Dragging inside the Hue Sphere sets the hue and saturation.
/// - Dragging on the vertical slider sets the brightness.
/// - Dragging on the horizontal slider below sets the opacity.
struct HueSpherePickerView: View {
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
                let sphereSize = min(width - sliderThickness, height - sliderThickness)
                let sphereRadius = sphereSize * 0.5
                
                VStack(alignment: .leading, spacing: Layout.stackSpacing) {
                    HStack(spacing: Layout.stackSpacing) {
                        
                        HueSphere(color: $color, storeColor: storeColor)
                            .positionIndicator(color: color, sphereRadius: sphereRadius)
                            .frame(width: sphereSize, height: sphereSize)
                        
                        VerticalSlider(
                            slider: BrightnessSlider(color: color),
                            value: $color.brightness,
                            thumbTint: Color(hue: color.hue, saturation: color.saturation, brightness: color.brightness),
                            storeColor: storeColor
                        )
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
