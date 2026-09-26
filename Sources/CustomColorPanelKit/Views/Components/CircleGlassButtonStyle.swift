//
//  CircleGlassButtonStyle.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 17/09/2026.
//

import SwiftUI


/// A button style that displays its label inside a circular glass background, tinting and scaling in response to hover and press interactions.
struct CircleGlass: ButtonStyle {
    /// Whether the cursor is currently hovering over the button.
    @State private var isHovering: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    /// The tint color applied to the glass in the press and hover effects, chosen for contrast against the system color scheme.
    private var hoveringTint: Color { colorScheme == .dark ? .white : .gray }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .background {
                Circle()
                    .fill(.clear)
                    .glassEffect(
                        .clear.tint(isHovering && !configuration.isPressed ? hoveringTint.opacity(0.25)
                                      :(configuration.isPressed) ? hoveringTint.opacity(0.5)
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
    /// A button style that displays its label inside a circular glass background, tinting and scaling in response to hover and press interactions.
    static var circleGlass: Self { CircleGlass() }
}
