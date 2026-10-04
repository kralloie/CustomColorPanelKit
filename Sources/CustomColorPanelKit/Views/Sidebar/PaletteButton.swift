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
    
    var string: String {
        switch self {
        case .system: "System"
        case .classic: "Classic"
        case .pastel: "Pastel"
        case .neon: "Neon"
        case .warm: "Warm"
        case .cool: "Cool"
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
struct PaletteButton: View {
    /// A binding to the current color being edited.
    @Binding var color: HSBAColor
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
        .accessibilityLabel("Palette")
        .popover(isPresented: $showingPopover, arrowEdge: .trailing) {
            VStack(spacing: 12) {
                HStack {
                    Button {
                        paletteIndex = abs(paletteIndex - 1 + Palette.allCases.count) % Palette.allCases.count
                    } label: {
                        Image(systemName: "chevron.left")
                            .bold()
                    }
                    .buttonStyle(.circleGlass)
                    .accessibilityLabel("Previous Palette")
                    
                    Spacer()
                    
                    ZStack {
                        Text(palette.string)
                        ForEach(Palette.allCases, id: \.self) { p in
                            Text(p.string)
                                .opacity(0)
                        }
                    }
                    .accessibilityRepresentation {
                        Text("\(palette.string) Palette")
                    }
                    
                    Spacer()
                    
                    Button {
                        paletteIndex = abs(paletteIndex + 1) % Palette.allCases.count
                    } label: {
                        Image(systemName: "chevron.right")
                            .bold()
                    }
                    .buttonStyle(.circleGlass)
                    .accessibilityLabel("Next Palette")
                }
                .bold()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 5) {
                    ForEach(palette.colors, id: \.self) { swatch in
                        ColorSwatch(swatch, $color, storeColor)
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
        /// A binding to the current color being edited.
        @Binding var color: HSBAColor
        /// A closure that stores the current color to the history after the swatch is selected.
        let storeColor: () -> Void
        /// Whether the cursor is hovering the swatch.
        @State private var isHovering: Bool = false
        
        init(_ swatch: Color, _ color: Binding<HSBAColor>, _ storeColor: @escaping () -> Void) {
            self.swatch = swatch
            self._color = color
            self.storeColor = storeColor
        }
        
        var body: some View {
            Button {
                color = .init(with: swatch)
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
}
