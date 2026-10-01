//
//  ColorComponentGroupButtonStyle.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 29/09/2026.
//

import SwiftUI

struct ColorComponentGroupButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    private var pressingTint: Color { colorScheme == .dark ? .white : .gray }
    
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
