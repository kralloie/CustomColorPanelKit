//
//  ColorSampler.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 27/06/2026.
//

import SwiftUI
import AppKit

func pickColorFromScreen(completion: @escaping (Color?) -> Void) {
    let sampler = NSColorSampler()
    sampler.show { nsColor in
        completion(nsColor.map { Color($0) })
    }
}

struct EyeDropperView: View {
    @Binding var pickedColor: HSBAColor
    var storeColor: (HSBAColor) -> Void
    
    var body: some View {
        Button {
            pickColorFromScreen { color in
                if let color {
                    let c = HSBAColor(with: color)
                    pickedColor = c
                    storeColor(c)
                }
            }
        } label: {
            Image(systemName: "eyedropper")
        }
        .buttonStyle(.plain)
    }
}
