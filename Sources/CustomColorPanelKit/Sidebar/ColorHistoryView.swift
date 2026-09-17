//
//  ColorHistoryView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 26/06/2026.
//

import SwiftUI

struct ColorHistoryView: View {
    var colorHistory: ColorHistory
    
    private let colorSize: CGFloat = 10
    private let spacing: CGFloat = 4
    private let maxColumns: CGFloat = 12
    private var maxWidth: CGFloat { maxColumns * colorSize + (maxColumns - 1) * spacing }
    
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
        .frame(maxWidth: maxWidth)
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
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
    }
}

extension ColorHistoryView {
    private struct ColorHistoryEntry: View {
        let index: Int
        let colorSize: CGFloat
        var colorHistory: ColorHistory
        let setColor: (HSBAColor) -> Void
        @State var isHovering: Bool = false
        
        var body: some View {
            if colorHistory.colors.indices.contains(index) {
                let c = colorHistory.colors[index]
                RoundedRectangle(cornerRadius: 2)
                    .fill(c.color)
                    .frame(width: colorSize, height: colorSize)
                    .onHover { isHovering = $0 }
                    .onTapGesture { setColor(c) }
                    .scaleEffect(isHovering ? 1.25 : 1)
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
                    .contextMenu{ ColorEntryContextMenu(color: c, entryColor: c, colorHistory: colorHistory, setColor: setColor) }
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(.separator, lineWidth: 1)
                    .frame(width: colorSize, height: colorSize)
            }
        }
    }
}

extension ColorHistoryView {
    struct ColorEntryContextMenu: View {
        var color: HSBAColor
        var entryColor: HSBAColor
        var colorHistory: ColorHistory
        let setColor: (HSBAColor) -> Void
        
        var body: some View {
            Button("Select") { setColor(entryColor) }
            
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
