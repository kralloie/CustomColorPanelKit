//
//  EyeDropperButton.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 27/06/2026.
//

import SwiftUI
import AppKit

func pickColorFromScreen(completion: @escaping @Sendable (Color?) -> Void) {
    let sampler = NSColorSampler()
    sampler.show { nsColor in
        completion(nsColor.map { Color($0) })
    }
}

@MainActor
struct EyeDropperButton: View {
    @Binding var pickedColor: HSBAColor
    let storeColor: () -> Void
    
    var body: some View {
        Button {
            pickColorFromScreen { color in
                if let color {
                    let c = HSBAColor(with: color)
                    Task { @MainActor in
                        pickedColor = c
                        storeColor()
                    }
                }
            }
        } label: {
            Image(systemName: "eyedropper")
        }
        .buttonStyle(.circleGlass)
    }
}
