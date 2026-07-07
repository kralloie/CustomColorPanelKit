//
//  HueWheelColorPicker.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 07/06/2026.
//

import SwiftUI

public struct HueWheelColorPicker: View {
    @Binding var color: HSBAColor
    var antialiasing: Bool = true
    var hueRotation: Bool = true
    var colorHistory: ColorHistory
    
    init(color: Binding<HSBAColor>, antialiasing: Bool = true, hueRotation: Bool = true, colorHistory: ColorHistory) {
        self._color = color
        self.antialiasing = antialiasing
        self.hueRotation = hueRotation
        self.colorHistory = colorHistory
    }
    
    public var body: some View {
        VStack {
            GeometryReader { geo in
                let size = geo.size.width
                let colorPickerGeometry = HueWheelGeometry(color: color, viewSize: geo.size, hueRotation: hueRotation)

                VStack {
                    ZStack {
                        HueRing(
                            color: $color,
                            size: size,
                            antialiasing: antialiasing,
                            storeColor: { colorHistory.add($0) }
                        )
                            .frame(width: size, height: size)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.clear)
                                    .frame(
                                        width: colorPickerGeometry.hueRingIndicatorSize.width,
                                        height: colorPickerGeometry.hueRingIndicatorSize.height
                                    )
                                    .overlay(alignment: .trailing) {
                                        LeftPointingTriangle()
                                            .fill(.primary)
                                            .frame(width: 20, height: 20)
                                            .shadow(radius: 2)
                                            .padding(.trailing, -10)
                                    }
                                    .rotationEffect(Angle(radians: -colorPickerGeometry.hueAngle))
                                    .offset(colorPickerGeometry.hueRingIndicatorOffset)
                                    .allowsHitTesting(false)
                            }
                            .background(
                                ScrollWheelMonitor { point, event in
                                    if point.x < 0 || point.y < 0 || point.x > size || point.y > size {
                                        return
                                    }
                                    
                                    let r = size * 0.5
                                    let dx = point.x - r
                                    let dy = point.y - r
                                    let dist = hypot(dx, dy)
                                    if dist > r || dist < r * 0.75 { return }
                                    
                                    let step: Double = 1 / 360
                                    let delta = event.scrollingDeltaY > 0 ? step : -step
                                    
                                    var hue = color.hue + delta
                                    hue = (hue > 1) ? 0 :(hue < 0) ? 1 : hue
                                    color.hue = hue
                                }
                            )
                        
                        HSBTriangle(
                            color: $color,
                            size: colorPickerGeometry.triangleSize,
                            antialiasing: antialiasing,
                            hueRotation: hueRotation,
                            storeColor: { colorHistory.add($0) }
                        )
                            .frame(width: colorPickerGeometry.triangleSize, height: colorPickerGeometry.triangleSize)
                            .overlay {
                                Circle()
                                    .stroke(color.brightness > 0.5 ? .black : .white, lineWidth: 1)
                                    .frame(width: 10, height: 10)
                                    .offset(colorPickerGeometry.hsbTriangleIndicatorOffset)
                            }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(8)
            
            OpacitySliderView(color: $color)
        }
        .frame(minWidth: 250, minHeight: 250)
    }
}
