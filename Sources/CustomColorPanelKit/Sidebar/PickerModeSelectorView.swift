//
//  PickerModeSelectorView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 12/08/2026.
//

import SwiftUI

struct PickerModeSelectorView: View {
    @Binding var selectedMode: PickerMode
    @State private var hoveringMode: PickerMode?
    private static let accentColor: Binding<HSBAColor> = .constant(HSBAColor(with: .accentColor))
    var body: some View {
        HStack {
            HSVSquare(color: Self.accentColor, storeColor: {})
                .frame(width: 20, height: 20)
                .allowsHitTesting(false)
                .selectorButton(for: .hsvSquare, selectedMode: $selectedMode, hoveringMode: $hoveringMode)
            
            HSVSphere(color: Self.accentColor, storeColor: {})
                .frame(width: 20, height: 20)
                .allowsHitTesting(false)
                .selectorButton(for: .hsvSphere, selectedMode: $selectedMode, hoveringMode: $hoveringMode)
            
            HueRing(color: Self.accentColor, storeColor: {})
                .frame(width: 20, height: 20)
                .overlay {
                    HSVTriangle(color:  Self.accentColor, hueRotation: false, storeColor: {})
                        .frame(width: 14, height: 14)
                }
                .allowsHitTesting(false)
                .selectorButton(for: .hueRing, selectedMode: $selectedMode, hoveringMode: $hoveringMode)
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 50)
                .clearGlassEffect(in: RoundedRectangle(cornerRadius: 50))
        }
        .padding(.bottom, 8)
    }
}

private extension View {
    func selectorButton(for mode: PickerMode, selectedMode: Binding<PickerMode>, hoveringMode: Binding<PickerMode?>) -> some View {
        self
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .glassEffect(
                        .regular.tint(
                            selectedMode.wrappedValue == mode ? .accentColor
                            : hoveringMode.wrappedValue == mode ? .gray
                            : .clear
                        ),
                        in: .rect(cornerRadius: 30)
                    )
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
            .onHover { hoveringMode.wrappedValue = $0 ? mode : nil }
            .onTapGesture { selectedMode.wrappedValue = mode }
            .animation(.easeInOut(duration: 0.1), value: hoveringMode.wrappedValue == mode)
            .animation(.easeInOut(duration: 0.1), value: selectedMode.wrappedValue == mode)
    }
}
