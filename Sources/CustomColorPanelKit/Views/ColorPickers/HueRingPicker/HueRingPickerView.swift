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
    static let ringInnerRatio: CGFloat = 0.75
}

// MARK: - HueRingPickerView

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
                        HueRing(color: color)
                        .positionIndicator(geometry: geometry)
                        .frame(width: ringSize, height: ringSize)
                        .modifier(HueRingDragModifier(color: $color, ringSize: ringSize, storeColor: storeColor))
                        .frame(maxWidth: .infinity)
                        
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
                    HueRingIndicator(rectangleWidth: Layout.hueRingIndicatorSize * 0.5, cornerRadius: 4)
                        .fill(.white)
                        .frame(width: Layout.hueRingIndicatorSize, height: Layout.hueRingIndicatorSize)
                        .shadow(radius: 1)
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

private struct HueRingDragModifier: ViewModifier {
    @Binding var color: HSBAColor
    let ringSize: CGFloat
    let storeColor: () -> Void

    @State private var gestureBegan = false
    @State private var hueAnimation: Task<Void, Never>?

    func body(content: Content) -> some View {
        content.gesture(dragGesture)
    }

    private func isOnRing(_ point: CGPoint) -> Bool {
        let radius = ringSize * 0.5
        let distance = hypot(point.x - radius, point.y - radius) / radius
        return (Layout.ringInnerRatio...1).contains(distance)
    }

    private func hue(at point: CGPoint) -> CGFloat {
        let radius = ringSize * 0.5
        var hue = atan2(radius - point.y, point.x - radius) / (2 * .pi)
        if hue < 0 { hue += 1 }
        return hue
    }

    private func animateHue(to target: CGFloat, duration: Duration = .milliseconds(100)) {
        hueAnimation?.cancel()
        let start = color.hue
        var delta = target - start
        if delta > 0.5 { delta -= 1 } else if delta < -0.5 { delta += 1 }
        let clock = ContinuousClock()
        let begin = clock.now

        hueAnimation = Task { @MainActor in
            while !Task.isCancelled {
                let t = min(1, (clock.now - begin) / duration)
                let eased = 1 - pow(1 - t, 3)
                var hue = (start + delta * eased).truncatingRemainder(dividingBy: 1)
                if hue < 0 { hue += 1 }
                color.hue = t >= 1 ? target : hue
                if t >= 1 { break }
                try? await Task.sleep(for: .milliseconds(8))
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard isOnRing(value.startLocation) else { return }
                let target = hue(at: value.location)

                if !gestureBegan {
                    gestureBegan = true
                    animateHue(to: target)
                } else {
                    hueAnimation?.cancel()
                    color.hue = target
                }
            }
            .onEnded { value in
                gestureBegan = false
                guard isOnRing(value.startLocation) else { return }
                Task { @MainActor in
                    await hueAnimation?.value
                    storeColor()
                }
            }
    }
}
