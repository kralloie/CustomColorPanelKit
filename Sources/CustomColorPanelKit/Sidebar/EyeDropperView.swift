//
//  EyeDropperView.swift
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
                        pickedColor = c
                        storeColor(c)
                    }
                }
            }
    }
}
