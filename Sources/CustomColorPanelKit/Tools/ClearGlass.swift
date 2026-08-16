//
//  ClearGlass.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 16/08/2026.
//

import SwiftUI

private struct ClearGlass<S: Shape>: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let shape: S
    
    func body(content: Content) -> some View {
        content.glassEffect(
            .clear.tint(colorScheme == .dark ? .black : .white),
            in: shape
        )
    }
}

extension View {
    func clearGlassEffect<S: Shape>(in shape: S = .capsule) -> some View {
        modifier(ClearGlass(shape: shape))
    }
}
