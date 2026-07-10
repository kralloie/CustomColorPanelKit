//
//  HueRingPickerView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 07/06/2026.
//

import SwiftUI

public struct HueRingPickerView: View {
    @Binding var color: HSBAColor
    let antialiasing: Bool
    let hueRotation: Bool
    let colorHistory: ColorHistory
    
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
                let colorPickerGeometry = HueRingPickerGeometry(color: color, viewSize: geo.size, hueRotation: hueRotation)

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
                            .overlay { HueRingPositionIndicator(colorPickerGeometry: colorPickerGeometry) }
                            .background(HueRingScrollHandler(hueRingSize: size, hue: $color.hue))
                        
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
    
    private struct HueRingScrollHandler: View {
        private static let hueStep: Double = 1.0 / 360.0
        
        let hueRingSize: CGFloat
        @Binding var hue: CGFloat
        
        var body: some View {
            ScrollWheelMonitor { point, event in
                if point.x < 0 || point.y < 0 || point.x > hueRingSize || point.y > hueRingSize {
                    return
                }
                
                let r = hueRingSize * 0.5
                let dx = point.x - r
                let dy = point.y - r
                let dist = hypot(dx, dy)
                if dist > r || dist < r * 0.75 { return }
                
                let delta = event.scrollingDeltaY > 0 ? Self.hueStep: -Self.hueStep
                
                var newHue = (hue + delta).truncatingRemainder(dividingBy: 1)
                if newHue < 0 { newHue += 1 }
                hue = newHue
            }
        }
    }
    
    private struct HueRingPositionIndicator: View {
        let colorPickerGeometry: HueRingPickerGeometry
        
        var body: some View {
            Rectangle()
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
    }
}
