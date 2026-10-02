//
//  ColorComponentGroupButtonStyle.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 29/09/2026.
//

import SwiftUI

/// A button style that displays its content as a rectangular row tinting it on pressed.
struct ColorComponentGroupButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .background {
                if configuration.isPressed {
                    Rectangle()
                        .fill(.background.tertiary)
                        .padding(.vertical, -1)
                }
            }
    }
}
