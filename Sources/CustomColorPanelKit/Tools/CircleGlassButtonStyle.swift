//
//  CircleGlassButtonStyle.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 17/09/2026.
//

import SwiftUI

struct CircleGlass: ButtonStyle {
    @State private var isHovering: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    private var hoveringTint: Color {
        colorScheme == .dark ? .white.opacity(0.25) : .gray.opacity(0.25)
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .background {
                Circle()
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(isHovering && !configuration.isPressed ? hoveringTint
                                      :(configuration.isPressed) ? .black.opacity(0.25)
                                      : .clear
                         ),
                         in: .circle
                    )
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
            }
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(.circle)
            .onHover { isHovering = $0 }
    }
}

extension ButtonStyle where Self == CircleGlass {
    static var circleGlass: Self { CircleGlass() }
}
