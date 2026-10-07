//
//  EyeDropperButton.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 27/06/2026.
//

import SwiftUI
import AppKit

/// Creates an instance of ``NSColorSampler`` and shows it on the screen.
func pickColorFromScreen(completion: @escaping @Sendable (Color?) -> Void) {
    let sampler = NSColorSampler()
    sampler.show { nsColor in
        completion(nsColor.map { Color($0) })
    }
}

/// A button that when pressed creates a color sampler instance letting the user pick a color from anywhere on the screen.
@MainActor
struct EyeDropperButton: View {
    /// A binding to the current color being edited.
    @Binding var currentColor: HSBAColor
    /// A closure that stores the current color to the history after the color sampler picks a color.
    let storeColor: () -> Void
    
    var body: some View {
        Button {
            pickColorFromScreen { color in
                if let color {
                    let c = HSBAColor(with: color)
                    Task { @MainActor in
                        currentColor = c
                        storeColor()
                    }
                }
            }
        } label: {
            Image(systemName: "eyedropper")
                .font(.system(size: 16))
        }
        .buttonStyle(.circleGlass)
        .accessibilityLabel(.actionEyeDropper)
    }
}
