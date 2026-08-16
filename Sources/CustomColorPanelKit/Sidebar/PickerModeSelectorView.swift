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
    var body: some View {
        HStack() {
            Spacer()
            
            HSVSquare(color: .constant(HSBAColor(with: .accentColor)), storeColor: {})
                .frame(width: 20, height: 20)
                .allowsHitTesting(false)
                .selectorButton(for: .hsvSquare, selectedMode: $selectedMode, hoveringMode: $hoveringMode)
            
            Spacer()
            
            HSVSphere(color: .constant(HSBAColor(with: .accentColor)), storeColor: {})
                .frame(width: 20, height: 20)
                .allowsHitTesting(false)
                .selectorButton(for: .hsvSphere, selectedMode: $selectedMode, hoveringMode: $hoveringMode)
             
            Spacer()
            
            HueRing(color: .constant(HSBAColor.init(with: .accentColor)), storeColor: {})
                .frame(width: 20, height: 20)
                .overlay {
                    HSVTriangle(color: .constant(HSBAColor(with: .accentColor)), hueRotation: false, storeColor: {})
                        .frame(width: 14, height: 14)
                }
                .allowsHitTesting(false)
                .selectorButton(for: .hueRing, selectedMode: $selectedMode, hoveringMode: $hoveringMode)
            
            Spacer()
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
        background {
            RoundedRectangle(cornerRadius: 10)
                .glassEffect(
                    .clear.tint(
                        selectedMode.wrappedValue == mode ? .accentColor
                        : hoveringMode.wrappedValue == mode ? .gray
                        : .clear
                    ),
                    in: .rect(cornerRadius: 10)
                )
                .frame(width: 35, height: 30)
        }
        .frame(width: 35, height: 30)
        .scaleEffect(selectedMode.wrappedValue == mode ? 1.1 : 1.0)
        .contentShape(.rect)
        .onHover { hoveringMode.wrappedValue = $0 ? mode : nil }
        .onTapGesture { selectedMode.wrappedValue = mode }
        .animation(.easeInOut(duration: 0.1), value: hoveringMode.wrappedValue == mode)
        .animation(.easeInOut(duration: 0.1), value: selectedMode.wrappedValue == mode)
    }
}
