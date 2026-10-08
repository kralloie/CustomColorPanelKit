//
//  PickerModeSelectorView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 12/08/2026.
//

import SwiftUI

/// A custom sectioned control for selecting a color picker mode.
///
/// Displays the available picker modes and clicking or dragging the indicator allows the user to change between the modes.
struct PickerModeSelectorView: View {
    /// The currently selected picker mode.
    @Binding var selectedMode: PickerMode
    /// The last location updated by the drag gesture.
    @GestureState private var dragX: CGFloat?
    
    /// All the available picker modes.
    private let modes = PickerMode.allCases
    /// The height of the view.
    private let height: CGFloat = 30
    /// The slide animation when clicking one of the modes.
    private let slide: Animation = .easeInOut(duration: 0.25)
    /// Whether there is an ongoing drag gesture.
    private var isDragging: Bool { dragX != nil }
    /// A constant binding to the accent color used to show the picker mode previews with the system accent color.
    private var accentColor: Binding<HSBAColor> { .constant(HSBAColor(with: NSColor.controlAccentColor)) }
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let segmentWidth = width / CGFloat(modes.count)
            ZStack(alignment: .leading) {
                Color.clear
                    .glassEffect(.clear, in: .capsule)
                
                Color.clear
                    .frame(width: segmentWidth)
                    .glassEffect(.clear.tint(.accentColor), in: .capsule)
                    .scaleEffect(isDragging ? 1.15 : 1)
                    .offset(x: indicatorOffset(segmentWidth: segmentWidth, width: width))
                    .animation(slide, value: isDragging)
                    .animation(slide, value: selectedMode)
                
                HStack(spacing: 0) {
                    ForEach(modes, id: \.self) { mode in
                        icon(for: mode).frame(maxWidth: .infinity)
                            .accessibilityRepresentation {
                                Button(mode.string) {
                                    selectedMode = mode
                                }
                            }
                    }
                }
                .allowsHitTesting(false)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(.pickerAccessibilityLabel)
            }
            .contentShape(.capsule)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragX) { value, state, _ in state = value.location.x }
                    .onEnded { value in
                        selectedMode = mode(at: value.location.x, segmentWidth: segmentWidth)
                    }
            )
        }
        .frame(height: height)
        .padding(.bottom, 8)
    }
    
    /// Returns the offset to position the indicator behind the selected picker mode based on the current width of the control.
    ///
    /// - Parameters:
    ///   - segmentWidth: The width of the view divided by the amount of available picker modes.
    ///   - width: The width of the view.
    private func indicatorOffset(segmentWidth: CGFloat, width: CGFloat) -> CGFloat {
        if let dragX {
            return (dragX - segmentWidth / 2).clamped(to: 0...(width - segmentWidth))
        }
        return CGFloat(modes.firstIndex(of: selectedMode) ?? 0) * segmentWidth
    }
    
    /// Returns a picker mode based on a drag position.
    ///
    /// - Parameters:
    ///   - x: The drag X location.
    ///   - segmentWidth: The width of the view divided by the amount of available picker modes.
    private func mode(at x: CGFloat, segmentWidth: CGFloat) -> PickerMode {
        guard segmentWidth > 0 else { return selectedMode }
        return modes[min(max(Int(x / segmentWidth), 0), modes.count - 1)]
    }
    
    /// Returns a preview of each picker mode to use as icon on the control segments.
    ///
    /// - Parameter mode: The mode that the returned view will represent.
    @ViewBuilder
    private func icon(for mode: PickerMode) -> some View {
        switch mode {
        case .hsvSquare:
            HSVSquare(color: accentColor, storeColor: {}).frame(width: 20, height: 20)
        case .hueSphere:
            HueSphere(color: accentColor, storeColor: {}).frame(width: 20, height: 20)
        case .hueRing:
            HueRing()
                .frame(width: 20, height: 20)
                .overlay {
                    HSVTriangle(color: accentColor, storeColor: {})
                        .frame(width: 14, height: 14)
                }
        }
    }
}
