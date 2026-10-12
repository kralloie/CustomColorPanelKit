//
//  DiceButton.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 14/09/2026.
//

import SwiftUI

/// A button that when pressed sets the current color being edited to a new pseudo-random generated color.
struct DiceButton: View, @MainActor Equatable {
    /// A function that sets the current color to the passed color.
    let setColor: (HSBAColor) -> Void
    /// A closure that stores the current color to the history after the button is pressed.
    let storeColor: () -> Void
    
    var body: some View {
        Button {
            setColor(HSBAColor(with: Color(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1))))
            storeColor()
        } label: {
            Image(systemName: "dice")
                .font(.system(size: 16))
        }
        .buttonStyle(.circleGlass)
        .accessibilityLabel(.actionRandomColor)
    }
    
    static func == (a: Self, b: Self) -> Bool { true }
}
