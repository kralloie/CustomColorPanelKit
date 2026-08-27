//
//  HueRingPickerView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 07/06/2026.
//

import SwiftUI

// MARK: - Layout

private enum Layout {
    static let hueRingMinSize: CGFloat = 250
    static let hueRingIndicatorSize: CGFloat = 20
    static let hsbTriangleIndicatorSize: CGFloat = 10
    static let stackSpacing: CGFloat = 10
    static let outerPadding: CGFloat = 20
}

// MARK: - HueRingPickerView

public struct HueRingPickerView: View {
    @Binding var color: HSBAColor
    let antialiasing: Bool
    let hueRotation: Bool
    let colorHistory: ColorHistory
    @State private var isHoveringRing: Bool = false
    
    init(color: Binding<HSBAColor>, antialiasing: Bool = true, hueRotation: Bool = true, colorHistory: ColorHistory) {
        self._color = color
        self.antialiasing = antialiasing
        self.hueRotation = hueRotation
        self.colorHistory = colorHistory
    }
    
    private func storeColor() { colorHistory.add(color) }
    
    public var body: some View {
        VStack {
            GeometryReader { proxy in
                let size = proxy.size.width
                let sliderThickness = size * 0.03
                let ringSize = size - sliderThickness
                let geometry = HueRingPickerGeometry(
                    color: color,
                    viewSize: CGSize(width: ringSize, height: ringSize),
                    hueRotation: hueRotation
                )
                
                VStack(spacing: Layout.stackSpacing) {
                    ZStack {
                        HueRing(
                            color: $color,
                            storeColor: storeColor
                        )
                        .positionIndicator(geometry: geometry)
                        .hueRingScrollHandler(isHovering: isHoveringRing, size: ringSize, hue: $color.hue, storeColor: storeColor)
                        .frame(width: ringSize, height: ringSize)
                        .frame(maxWidth: .infinity)
                        .onHover { isHoveringRing = $0 }
                        
                        HSVTriangle(
                            color: $color,
                            hueRotation: hueRotation,
                            storeColor: storeColor
                        )
                        .positionIndicator(
                            brightness: color.brightness,
                            offset: geometry.hsbTriangleIndicatorOffset,
                            color: Color(hue: color.hue, saturation: color.saturation, brightness: color.brightness)
                        )
                        .frame(width: geometry.triangleSize, height: geometry.triangleSize)
                    }
                    OpacitySliderView(color: $color)
                        .frame(width: ringSize, height: sliderThickness)
                }

            }
            .aspectRatio(1, contentMode: .fit)
            .padding(Layout.outerPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(minWidth: Layout.hueRingMinSize, minHeight: Layout.hueRingMinSize)
    }
}

// MARK: - View Modifiers

private extension View {
    func hueRingScrollHandler(isHovering: Bool, size: CGFloat, hue: Binding<CGFloat>, storeColor: @escaping () -> Void) -> some View {
        background {
            ScrollWheelMonitor(isHovering: isHovering, storeColor: storeColor) { point, event in
                if point.x < 0 || point.y < 0 || point.x > size || point.y > size {
                    return
                }
                
                let r = size * 0.5
                let dist = hypot(point.x - r, point.y - r)
                if dist > r || dist < r * 0.75 { return }
                
                let delta = event.scrollingDeltaY > 0 ? GeometryConstants.hueStep: -GeometryConstants.hueStep
                
                var newHue = (hue.wrappedValue + delta).truncatingRemainder(dividingBy: 1)
                if newHue < 0 { newHue += 1 }
                hue.wrappedValue = newHue
            }
        }
    }
}

// MARK: - HueRing

private extension HueRing {
    func positionIndicator(geometry: HueRingPickerGeometry) -> some View {
        overlay {
            Rectangle()
                .fill(.clear)
                .frame(
                    width: geometry.hueRingIndicatorSize.width,
                    height: geometry.hueRingIndicatorSize.height
                )
                .overlay(alignment: .trailing) {
                    LeftPointingTriangle()
                        .fill(.primary)
                        .frame(width: Layout.hueRingIndicatorSize, height: Layout.hueRingIndicatorSize)
                        .shadow(radius: 2)
                        .padding(.trailing, -Layout.hueRingIndicatorSize * 0.5)
                }
                .rotationEffect(Angle(radians: -geometry.hueAngle))
                .offset(geometry.hueRingIndicatorOffset)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - HSBTriangle
 
private extension HSVTriangle {
    func positionIndicator(brightness: CGFloat, offset: CGSize, color: Color) -> some View {
        overlay {
            Circle()
                .fill(color)
                .stroke(brightness > 0.5 ? .black : .white, lineWidth: 1)
                .frame(width: Layout.hsbTriangleIndicatorSize)
                .offset(offset)
        }
    }
}

// MARK: - HueRingPickerGeometry

private struct HueRingPickerGeometry {
    let color: HSBAColor
    let viewSize: CGSize
    let viewRadius: CGFloat
    let triangleSize: CGFloat
    let hueAngle: CGFloat
    let hueRingIndicatorSize: CGSize
    let hueRotation: Bool
    
    var hueRingIndicatorOffset: CGSize {
        CGSize(
            width: cos(hueAngle) * 0.875 * viewRadius,
            height: -sin(hueAngle) * 0.875 * viewRadius,
        )
    }
    
    var hsbTriangleIndicatorOffset: CGSize {
        let v = color.brightness
        let s = color.saturation

        let w0 = v * s
        let w1 = 1 - v
        let w2 = v * (1 - s)

        let r = triangleSize * 0.5
        let angle = hueRotation ? hueAngle : .pi * 0.5
        let offset: CGFloat = GeometryConstants.triangleVertexSpacing

        let v0 = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
        let v1 = CGPoint(x: cos(angle + offset) * r, y: sin(angle + offset) * r)
        let v2 = CGPoint(x: cos(angle + offset * 2) * r, y: sin(angle + offset * 2) * r)

        let px = w0 * v0.x + w1 * v1.x + w2 * v2.x
        let py = w0 * v0.y + w1 * v1.y + w2 * v2.y

        return CGSize(width: px, height: -py)
    }

    init(color: HSBAColor, viewSize: CGSize, hueRotation: Bool) {
        self.color = color
        self.viewSize = viewSize
        self.viewRadius = viewSize.width * 0.5
        self.triangleSize = viewRadius * 1.25
        self.hueAngle = color.hue * 2 * .pi
        self.hueRingIndicatorSize = CGSize(width: viewSize.width * 0.125, height: 1)
        self.hueRotation = hueRotation
    }
}
