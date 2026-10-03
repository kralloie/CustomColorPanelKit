//
//  HueRingPickerView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 07/06/2026.
//

import SwiftUI

/// Layout values for ``HueRingPickerView``.
private enum Layout {
    static let hueRingMinSize: CGFloat = 250
    static let stackSpacing: CGFloat = 10
    static let outerPadding: CGFloat = 20
    static let ringInnerRatio: CGFloat = 0.75
}

/// A color picker with a hue ring, an HSV triangle inside it and an opacity slider below.
///
/// - Dragging on the ring sets the hue.
/// - Dragging inside the HSV triangle sets the saturation and brightness.
/// - Dragging the slider sets the opacity.
///
/// The view keeps a square aspect ratio and has a minimum size. The slider is as wide as the ring, and
/// its thickness is a small fraction of the available width.
struct HueRingPickerView: View {
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// The object storing and managing previously selected colors through the picker session.
    let colorHistory: ColorHistory
    
    /// Stores the current color in the history
    ///
    /// Passed to the subviews as a closure, so they can commit a color without needing to know about the ``ColorHistory`` object.
    private func storeColor() { colorHistory.add(color) }
    
    public var body: some View {
        VStack {
            GeometryReader { proxy in
                let size = proxy.size.width
                let sliderThickness = size * 0.03
                let ringSize = size - sliderThickness
                let geometry = HueRingPickerGeometry(
                    color: color,
                    viewSize: CGSize(width: ringSize, height: ringSize)
                )
                
                VStack(spacing: Layout.stackSpacing) {
                    ZStack {
                        HueRing()
                        .positionIndicator(geometry: geometry)
                        .frame(width: ringSize, height: ringSize)
                        .modifier(HueRingDragModifier(color: $color, ringSize: ringSize, storeColor: storeColor))
                        .frame(maxWidth: .infinity)
                        
                        HSVTriangle(
                            color: $color,
                            storeColor: storeColor
                        )
                        .positionIndicator(
                            brightness: color.brightness,
                            offset: geometry.hsvTriangleIndicatorOffset,
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


/// An object that stores and calculates the needed measurements for placing indicators of ``HueRingPickerView``.
struct HueRingPickerGeometry {
    /// The current color the indicators are positioned for.
    let color: HSBAColor
    /// The size of the hue ring.
    let viewSize: CGSize
    /// The radius of the hue ring.
    let viewRadius: CGFloat
    /// The side length of the square the triangle is drawn in.
    let triangleSize: CGFloat
    /// The hue as an angle in radians.
    let hueAngle: CGFloat
    /// The size of the strip that holds the hue indicator.
    let hueRingIndicatorSize: CGSize
    /// The offset from the ring's center to the hue indicator.
    var hueRingIndicatorOffset: CGSize {
        CGSize(
            width: cos(hueAngle) * 0.875 * viewRadius,
            height: -sin(hueAngle) * 0.875 * viewRadius,
        )
    }
    
    /// The offset from the triangle's center to the saturation and brightness indicator using
    /// the barycentric weights of each vertex.
    ///
    /// - Note: The vertex order must mirror the order used to draw the vertices in the shader and `getVerticesForTriangle` in ``HSVTriangle``.
    var hsvTriangleIndicatorOffset: CGSize {
        let v = color.brightness
        let s = color.saturation

        let w0 = v * s
        let w1 = 1 - v
        let w2 = v * (1 - s)

        let r = triangleSize * 0.5
        let angle = hueAngle
        let offset: CGFloat = GeometryConstants.triangleVertexSpacing

        let v0 = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
        let v1 = CGPoint(x: cos(angle + offset) * r, y: sin(angle + offset) * r)
        let v2 = CGPoint(x: cos(angle + offset * 2) * r, y: sin(angle + offset * 2) * r)

        let px = w0 * v0.x + w1 * v1.x + w2 * v2.x
        let py = w0 * v0.y + w1 * v1.y + w2 * v2.y

        return CGSize(width: px, height: -py)
    }

    init(color: HSBAColor, viewSize: CGSize) {
        self.color = color
        self.viewSize = viewSize
        self.viewRadius = viewSize.width * 0.5
        self.triangleSize = viewRadius * 1.25
        self.hueAngle = color.hue * 2 * .pi
        self.hueRingIndicatorSize = CGSize(width: viewSize.width * 0.125, height: 1)
    }
}

/// A view modifier that sets the hue by dragging on a ``HueRing``.
///
/// The ring is drawn in a square view, so the modifier ignores drags that start in points where the magnitude is
/// greater than 1.0 or lesser than 0.75.
///
/// Pressing animates the hue to the pressed angle, taking the shorter way around the circle while dragging changes the value instantly.
private struct HueRingDragModifier: ViewModifier {
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// The side length of the ring's square view.
    let ringSize: CGFloat
    /// A closure called when a drag that started on the ring ends to store the color to the history.
    let storeColor: () -> Void

    /// Whether the current drag has already reported its first change, so only the press animates.
    @State private var gestureBegan = false
    /// The task running the animation that starts when the ring is pressed.
    @State private var hueAnimation: Task<Void, Never>?

    func body(content: Content) -> some View {
        content.gesture(dragGesture)
    }
    
    /// Returns whether a point lies on the ring itself, not in its hole or the corners of its square.
    ///
    /// - Parameter point: A point in the ring's local coordinates.
    private func isOnRing(_ point: CGPoint) -> Bool {
        let radius = ringSize * 0.5
        let distance = hypot(point.x - radius, point.y - radius) / radius
        return (Layout.ringInnerRatio...1).contains(distance)
    }

    /// Returns the hue for the angle of a point around the ring's center.
    ///
    /// The vertical axis is flipped, because SwiftUI's Y axis grows downward.
    ///
    /// - Parameter point: A point in the ring's local coordinates.
    private func hue(at point: CGPoint) -> CGFloat {
        let radius = ringSize * 0.5
        var hue = atan2(radius - point.y, point.x - radius) / (2 * .pi)
        if hue < 0 { hue += 1 }
        return hue
    }

    /// Animates the hue to a target value, taking the shorter way around the circle.
    ///
    /// - Parameters:
    ///   - target: The hue to animate to, from 0.0 to 1.0.
    ///   - duration: How long the animation takes.
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

    
    /// The gesture that handles the dragging inside the Hue Ring.
    ///
    /// Modifies the hue based on the angle of the position indicator.
    ///
    /// Drags outside that start outside the ring bounds are ignored and the pointer is clamped when it leaves the shape.
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
