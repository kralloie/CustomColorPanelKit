//
//  ColorHistoryView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 26/06/2026.
//

import SwiftUI

struct ColorHistoryView: View {
    @Binding var color: HSBAColor
    @State var hoveredIndex: Int? = nil
    
    var colorHistory: ColorHistory
    
    private let colorSize: CGFloat = 10
    private let spacing: CGFloat = 4
    private let maxColumns: CGFloat = 12
    private var maxWidth: CGFloat { maxColumns * colorSize + (maxColumns - 1) * spacing }
    
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: colorSize, maximum: colorSize), spacing: spacing)
            ],
            spacing: spacing
        ) {
            ForEach(0..<144, id: \.self) { i in
                ColorHistoryEntry(color: $color, hoveredIndex: $hoveredIndex, index: i, colorSize: colorSize, colorHistory: colorHistory)
            }
        }
        .frame(maxWidth: maxWidth)
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .glassEffect(.regular, in: .rect(cornerRadius: 8))
        }
    }
}

extension ColorHistoryView {
    private struct ColorHistoryEntry: View {
        @Binding var color: HSBAColor
        @Binding var hoveredIndex: Int?
        let index: Int
        let colorSize: CGFloat
        var colorHistory: ColorHistory
        
        var body: some View {
            if colorHistory.colors.indices.contains(index) {
                let c = colorHistory.colors[index]
                let isHovering = hoveredIndex == index
                RoundedRectangle(cornerRadius: 2)
                    .fill(c.color)
                    .stroke(Color.accentColor, lineWidth: isHovering ? 1 : 0)
                    .frame(width: colorSize, height: colorSize)
                    .onHover { hovering in hoveredIndex = hovering ? index : nil }
                    .onTapGesture {
                        var newColor = c
                        newColor.alpha = color.alpha
                        color = newColor
                        hoveredIndex = nil
                    }
                    .scaleEffect(isHovering ? 1.25 : 1)
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
                    .contextMenu{ ColorEntryContextMenu(color: $color, entryColor: c, colorHistory: colorHistory) }
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
        @Binding var color: HSBAColor
        var entryColor: HSBAColor
        var colorHistory: ColorHistory
        
        var body: some View {
            Button("Select") { color = entryColor }
            
            Menu {
                Button("HEX") { NSPasteboard.copy(color.hexString) }
                
                Button("HSV") { NSPasteboard.copy(color.hsvString) }
                
                Button("HSL") { NSPasteboard.copy(color.hsl.string) }
                
                Button("RGB") { NSPasteboard.copy(color.rgb.string) }
                
                Button("CMYK") { NSPasteboard.copy(color.cmyk.string) }
                
            } label: {
                Label("Copy As", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button() {
                colorHistory.delete(color)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
