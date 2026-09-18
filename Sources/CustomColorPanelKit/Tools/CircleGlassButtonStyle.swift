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
                    .glassEffect(.regular.tint(isHovering ? hoveringTint : .clear), in: .circle)
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
            }
            .contentShape(.circle)
            .onHover { isHovering = $0 }
    }
}

extension ButtonStyle where Self == CircleGlass {
    static var circleGlass: Self { CircleGlass() }
}
