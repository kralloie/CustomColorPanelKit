//
//  PickerModeSelectorView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 12/08/2026.
//

import SwiftUI

struct PickerModeSelectorView: View {
    @Binding var selectedMode: PickerMode
    @GestureState private var dragX: CGFloat?
    
    private let modes = PickerMode.allCases
    private let height: CGFloat = 30
    private let slide: Animation = .easeInOut(duration: 0.25)
    
    private var isDragging: Bool { dragX != nil }
    private var accentColor: Binding<HSBAColor> { .constant(HSBAColor(with: .accentColor))}
    
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
                .accessibilityLabel("Color Picker Mode")
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
    
    private func indicatorOffset(segmentWidth: CGFloat, width: CGFloat) -> CGFloat {
        if let dragX {
            return (dragX - segmentWidth / 2).clamped(to: 0...(width - segmentWidth))
        }
        return CGFloat(modes.firstIndex(of: selectedMode) ?? 0) * segmentWidth
    }
    
    private func mode(at x: CGFloat, segmentWidth: CGFloat) -> PickerMode {
        guard segmentWidth > 0 else { return selectedMode }
        return modes[min(max(Int(x / segmentWidth), 0), modes.count - 1)]
    }
    
    @ViewBuilder
    private func icon(for mode: PickerMode) -> some View {
        switch mode {
        case .hsvSquare:
            HSVSquare(color: accentColor, storeColor: {}).frame(width: 20, height: 20)
        case .hsvSphere:
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
