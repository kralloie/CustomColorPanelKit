//
//  PickerModeSelectorView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 12/08/2026.
//

import SwiftUI

struct PickerModeSelectorView: View {
    @Binding var selectedMode: PickerMode
    @State private var selectedModeIndex: Int
    @State private var isDragging: Bool = false
    @State private var indicatorPosition: CGFloat = 0
    
    init(selectedMode: Binding<PickerMode>) {
        self._selectedMode = selectedMode
        self._selectedModeIndex = State(
            initialValue: selectedMode.wrappedValue == .hueRing ? 2 :
                          selectedMode.wrappedValue == .hsvSphere ? 1 : 0
        )
    }
    
    private var accentColor: Binding<HSBAColor> {
        Binding(
            get: { HSBAColor(with: .accentColor) },
            set: { _ in  }
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            let buttonWidth = proxy.size.width / 3
            HStack(spacing: 0) {
                HSVSquare(color: accentColor, storeColor: {})
                    .frame(width: 20, height: 20)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity)
                
                HSVSphere(color: accentColor, storeColor: {})
                    .frame(width: 20, height: 20)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity)
                
                HueRing(color: accentColor, storeColor: {})
                    .frame(width: 20, height: 20)
                    .overlay {
                        HSVTriangle(color:  accentColor, hueRotation: true, storeColor: {})
                            .frame(width: 14, height: 14)
                    }
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 30)
            .background {
                RoundedRectangle(cornerRadius: 50)
                    .clearGlassEffect(in: RoundedRectangle(cornerRadius: 50))
                RoundedRectangle(cornerRadius: 50)
                    .fill(.white.opacity(0.25))
                    .frame(width: buttonWidth)
                    .position(
                        x: isDragging ? indicatorPosition.clamped(to: (buttonWidth * 0.5)...proxy.size.width - (buttonWidth * 0.5)) :
                            (CGFloat(selectedModeIndex) * buttonWidth) + buttonWidth * 0.5,
                        y: 15
                    )
                    .animation(.easeInOut(duration: 0.25), value: isDragging)
                    .animation(.easeInOut(duration: 0.25), value: selectedModeIndex)
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        selectedModeIndex = min(2, Int(max(0, min(proxy.size.width, value.location.x)) / buttonWidth))
                        selectedMode = selectedModeIndex == 0 ? .hsvSquare :(selectedModeIndex == 1) ? .hsvSphere : .hueRing
                    }
            )
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if !isDragging { isDragging = true }
                        let posX = max(0, min(proxy.size.width, value.location.x))
                        selectedModeIndex = min(2, (Int(posX / buttonWidth)))
                        indicatorPosition = posX
                    }
                    .onEnded { _ in
                        isDragging = false
                        selectedMode = selectedModeIndex == 0 ? .hsvSquare :(selectedModeIndex == 1) ? .hsvSphere : .hueRing
                    }
            )
        }
        .frame(height: 30)
        .padding(.bottom, 8)
    }
}

private extension View {
    func selectorButton() -> some View {
        self
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.clear)
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 30)
            .frame(maxWidth: .infinity)
    }
}
