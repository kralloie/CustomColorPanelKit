//
//  PaletteButton.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 14/09/2026.
//

import SwiftUI

/// An enum representing a palette with a name and with a set of 12 colors.
enum Palette: CaseIterable {
    case system, classic, pastel, neon, warm, cool
    
    var title: LocalizedStringResource {
        switch self {
        case .system: .paletteSystem
        case .classic: .paletteClassic
        case .pastel: .palettePastel
        case .neon: .paletteNeon
        case .warm: .paletteWarm
        case .cool: .paletteCool
        }
    }
    
    var colors: [Color] {
        switch self {
            
        case .system: [
            .red, .orange, .yellow, .green,
            .cyan, .blue, .purple, .pink,
            .brown, .black, .white, .gray
        ]
            
        case .classic: [
            Color(red: 1.0, green: 0.0, blue: 0.0),
            Color(red: 1.0, green: 0.5, blue: 0.0),
            Color(red: 1.0, green: 1.0, blue: 0.0),
            Color(red: 0.0, green: 1.0, blue: 0.0),
            Color(red: 0.0, green: 1.0, blue: 1.0),
            Color(red: 0.0, green: 0.0, blue: 1.0),
            Color(red: 0.5, green: 0.0, blue: 1.0),
            Color(red: 1.0, green: 0.0, blue: 0.5),
            Color(red: 0.5, green: 0.25, blue: 0.0),
            Color(red: 0, green: 0, blue: 0),
            Color(red: 1, green: 1, blue: 1),
            Color(hue: 0, saturation: 0, brightness: 0.5)
        ]
            
        case .pastel: [
            Color(red: 1.0, green: 0.702, blue: 0.729),
            Color(red: 1.0, green: 0.875, blue: 0.729),
            Color(red: 1.0, green: 1.0, blue: 0.729),
            Color(red: 0.729, green: 1.0, blue: 0.788),
            Color(red: 0.729, green: 0.882, blue: 1.0),
            Color(red: 0.843, green: 0.729, blue: 1.0),
            Color(red: 1.0, green: 0.729, blue: 0.882),
            Color(red: 0.816, green: 0.816, blue: 0.816),
            Color(red: 0.788, green: 0.698, blue: 0.608),
            Color(red: 0.749, green: 0.906, blue: 0.906),
            Color(red: 0.878, green: 0.788, blue: 1.0),
            Color(red: 1.0, green: 1.0, blue: 1.0)
        ]
            
        case .neon: [
            Color(red: 1.0, green: 0.0, blue: 0.333),
            Color(red: 1.0, green: 0.4, blue: 0.0),
            Color(red: 1.0, green: 1.0, blue: 0.0),
            Color(red: 0.224, green: 1.0, blue: 0.078),
            Color(red: 0.0, green: 1.0, blue: 1.0),
            Color(red: 0.0, green: 0.533, blue: 1.0),
            Color(red: 0.4, green: 0.0, blue: 1.0),
            Color(red: 1.0, green: 0.0, blue: 1.0),
            Color(red: 1.0, green: 0.078, blue: 0.576),
            Color(red: 0.0, green: 1.0, blue: 0.533),
            Color(red: 1.0, green: 1.0, blue: 1.0),
            Color(red: 0.0, green: 0.0, blue: 0.0)
        ]
            
        case .warm: [
            Color(red: 1.0, green: 0.0, blue: 0.0),
            Color(red: 1.0, green: 0.251, blue: 0.0),
            Color(red: 1.0, green: 0.502, blue: 0.0),
            Color(red: 1.0, green: 0.753, blue: 0.0),
            Color(red: 1.0, green: 0.918, blue: 0.0),
            Color(red: 0.863, green: 0.424, blue: 0.0),
            Color(red: 0.729, green: 0.251, blue: 0.0),
            Color(red: 0.502, green: 0.0, blue: 0.0),
            Color(red: 0.796, green: 0.267, blue: 0.267),
            Color(red: 0.957, green: 0.502, blue: 0.267),
            Color(red: 0.957, green: 0.8, blue: 0.267),
            Color(red: 0.329, green: 0.125, blue: 0.063)
        ]
            
        case .cool: [
            Color(red: 0.0, green: 1.0, blue: 1.0),
            Color(red: 0.0, green: 0.753, blue: 1.0),
            Color(red: 0.0, green: 0.502, blue: 1.0),
            Color(red: 0.0, green: 0.251, blue: 1.0),
            Color(red: 0.0, green: 0.0, blue: 1.0),
            Color(red: 0.251, green: 0.0, blue: 1.0),
            Color(red: 0.502, green: 0.0, blue: 1.0),
            Color(red: 0.753, green: 0.0, blue: 1.0),
            Color(red: 0.0, green: 0.502, blue: 0.502),
            Color(red: 0.0, green: 0.753, blue: 0.753),
            Color(red: 0.251, green: 0.502, blue: 0.753),
            Color(red: 0.251, green: 0.251, blue: 0.502)
        ]
        }
    }
}

/// A button that shows a pop-over with different color palettes to choose and use as reference.
struct PaletteButton: View, @MainActor Equatable {
    /// A function that sets the current color to the passed color.
    let setColor: (HSBAColor) -> Void
    /// A closure that stores the current color to the history after a palette color is selected.
    let storeColor: () -> Void
    /// Whether the pop-over is being shown.
    @State private var showingPopover: Bool = false
    /// The index of the current palette being shown.
    @State private var paletteIndex: Int = 0
    /// All the palette presets.
    private var palette: Palette { Palette.allCases[paletteIndex] }
    
    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            Image(systemName: "paintpalette")
                .font(.system(size: 16))
        }
        .buttonStyle(.circleGlass)
        .accessibilityLabel(.paletteButton)
        .popover(isPresented: $showingPopover, arrowEdge: .trailing) {
            VStack(spacing: 12) {
                let paletteName = String(localized: palette.title)
                HStack {
                    Button {
                        paletteIndex = abs(paletteIndex - 1 + Palette.allCases.count) % Palette.allCases.count
                    } label: {
                        Image(systemName: "chevron.backward")
                            .bold()
                    }
                    .buttonStyle(.circleGlass)
                    .accessibilityLabel(.palettePrevious)
                    
                    Spacer()
                    
                    ZStack {
                        Text(palette.title)
                        ForEach(Palette.allCases, id: \.self) { p in
                            Text(p.title)
                                .opacity(0)
                        }
                    }
                    .accessibilityRepresentation {
                        Text(.paletteAccessibilityTitle(paletteName))
                    }
                    
                    Spacer()
                    
                    Button {
                        paletteIndex = abs(paletteIndex + 1) % Palette.allCases.count
                    } label: {
                        Image(systemName: "chevron.forward")
                            .bold()
                    }
                    .buttonStyle(.circleGlass)
                    .accessibilityLabel(.paletteNext)
                }
                .bold()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 5) {
                    ForEach(palette.colors, id: \.self) { swatch in
                        ColorSwatch(swatch: swatch, setColor: setColor, storeColor: storeColor)
                    }
                }
            }
            .padding(12)
        }

    }
    
    /// Represents one of the palette colors as a clickable swatch.
    private struct ColorSwatch: View {
        /// The color that this swatch represents.
        let swatch: Color
        /// A function that sets the current color to the passed color.
        let setColor: (HSBAColor) -> Void
        /// A closure that stores the current color to the history after the swatch is selected.
        let storeColor: () -> Void
        /// Whether the cursor is hovering the swatch.
        @State private var isHovering: Bool = false
        
        var body: some View {
            Button {
                setColor(HSBAColor(with: swatch))
                storeColor()
            } label: {
                Circle()
                    .fill(swatch)
                    .shadow(color: .black, radius: 1)
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
            }
            .frame(width: 15, height: 15)
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
            .scaleEffect(isHovering ? 1.15 : 1)
            .animation(.easeInOut(duration: 0.1), value: isHovering)
            .accessibilityLabel(Text(HSBAColor(with: swatch).hexString).speechSpellsOutCharacters(true))
        }
    }
    
    static func == (a: Self, b: Self) -> Bool { true }
}
