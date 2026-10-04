//
//  DiceButton.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 14/09/2026.
//

import SwiftUI

/// A button that when pressed sets the current color being edited to a new pseudo-random generated color.
struct DiceButton: View {
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
    /// A closure that stores the current color to the history after the button is pressed.
    let storeColor: () -> Void
    
    var body: some View {
        Button {
            color.rgb = .init(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1))
            storeColor()
        } label: {
            Image(systemName: "dice")
                .font(.system(size: 16))
        }
        .buttonStyle(.circleGlass)
        .accessibilityLabel("Random Color")
    }
}
