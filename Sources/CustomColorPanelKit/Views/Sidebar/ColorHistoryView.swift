//
//  ColorHistoryView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 26/06/2026.
//

import SwiftUI

/// A grid that displays the colors stored in ``ColorHistory``.
struct ColorHistoryView: View {
    /// The instance of the color history object that stores the colors.
    var colorHistory: ColorHistory
    
    /// The size of each color swatch.
    private let colorSize: CGFloat = 10
    /// The spacing between each color swatch.
    private let spacing: CGFloat = 4
    /// The max amount of columns in the grid.
    private let maxColumns: CGFloat = 12
    /// The max width that the grid will take.
    private var gridWidth: CGFloat { maxColumns * colorSize + (maxColumns - 1) * spacing }
    /// A closure that sets the color being edited to the selected color in the grid.
    private func setColor(_ c: HSBAColor) { colorHistory.pendingChange = c }
    
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: colorSize, maximum: colorSize), spacing: spacing)
            ],
            spacing: spacing
        ) {
            ForEach(0..<144, id: \.self) { i in
                ColorHistoryEntry(
                    index: i,
                    colorSize: colorSize,
                    colorHistory: colorHistory,
                    setColor: setColor
                )
            }
        }
        .frame(maxWidth: gridWidth)
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.background.secondary)
        }
        .contextMenu {
            Button() {
                colorHistory.clear()
            } label: {
                Label("Clear History", systemImage: "trash")
            }
            .disabled(colorHistory.colors.isEmpty)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color History")
    }
}

extension ColorHistoryView {
    /// Represents an entry in the color history and an element in the grid.
    private struct ColorHistoryEntry: View {
        
        /// The index used to track this element both inside the grid and inside ``ColorHistory``.
        let index: Int
        /// The size of the swatch.
        let colorSize: CGFloat
        /// The color history object that stores the colors.
        var colorHistory: ColorHistory
        /// A closure that sets the current color being edited to this entry's color.
        let setColor: (HSBAColor) -> Void
        /// Whether the cursor is hovering the swatch.
        @State var isHovering: Bool = false
        
        var body: some View {
            if colorHistory.colors.indices.contains(index) {
                let c = colorHistory.colors[index]
                Button {
                    setColor(c)
                } label: {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(c.color)
                }
                .frame(width: colorSize, height: colorSize)
                .buttonStyle(.plain)
                .onHover { isHovering = $0 }
                .scaleEffect(isHovering ? 1.25 : 1)
                .animation(.easeInOut(duration: 0.1), value: isHovering)
                .contextMenu{ ColorEntryContextMenu(color: c, colorHistory: colorHistory, setColor: setColor) }
                .accessibilityLabel(Text("Entry \(index + 1) \(Text(c.hexString).speechSpellsOutCharacters(true))"))
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(.separator, lineWidth: 1)
                    .frame(width: colorSize, height: colorSize)
            }
        }
    }
}

extension ColorHistoryView {
    
    /// The context menu for each ``ColorHistoryEntry``.
    struct ColorEntryContextMenu: View {
        /// The color that this entry represents.
        var color: HSBAColor
        /// The color history object that stores the colors.
        var colorHistory: ColorHistory
        /// A closure that sets the current color being edited to this entry's color.
        let setColor: (HSBAColor) -> Void
        
        var body: some View {
            Button("Select") { setColor(color) }
            
            CopyColorMenu(color: color)
            
            Divider()
            
            Button() {
                colorHistory.delete(color)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
