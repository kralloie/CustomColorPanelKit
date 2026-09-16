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
    @State private var isHovering: Bool = false
    
    var body: some View {
        Image(systemName: "eyedropper")
            .frame(width: 18, height: 18)
            .padding(4)
            .contentShape(Circle())
            .onHover { isHovering = $0 }
            .animation(.easeInOut(duration: 0.1), value: isHovering)
            .onTapGesture {
                pickColorFromScreen { color in
                    if let color {
                        let c = HSBAColor(with: color)
                        Task { @MainActor in
                            pickedColor = c
                            storeColor()
                        }
                    }
                }
            }
            .background {
                Circle()
                    .glassEffect(.clear.tint(isHovering ? .gray : .clear), in: Circle())
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
            }
    }
}
