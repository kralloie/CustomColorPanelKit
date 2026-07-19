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
    private let columns: Int = 12
    
    private var frameSize: CGFloat {
        CGFloat(columns) * (colorSize + spacing)
    }
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.fixed(colorSize), spacing: spacing), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: spacing) {
            ForEach(0..<(columns * columns), id: \.self) { i in
                ColorHistoryEntry(color: $color, hoveredIndex: $hoveredIndex, index: i, colorSize: colorSize, colorHistory: colorHistory)
            }
        }
        .frame(width: frameSize, height: frameSize)
        .padding(.top, 16)
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
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
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
                Button("HEX") {
                    NSPasteboard.copy(String(format: "#%06X", color.hex))
                }
                
                Button("HSV") {
                    NSPasteboard.copy(
                        String(
                            format: "hsv(%1$.0f°, %2$.0f%%, %3$.0f%%)",
                            color.hue * 360, color.saturation * 100, color.brightness * 100
                        )
                    )
                }
                
                Button("HSL") {
                    NSPasteboard.copy(
                        String(
                            format: "hsl(%1$.0f°, %2$.0f%%, %3$.0f%%)",
                            color.hue * 360, color.hsl.saturation * 100, color.hsl.lightness * 100
                        )
                    )
                }
                
                Button("RGB") {
                    NSPasteboard.copy(
                        String(
                            format: "rgb(%1$.0f, %2$.0f, %3$.0f)",
                            color.rgb.red * 255, color.rgb.green * 255, color.rgb.blue * 255
                        )
                    )
                }
                
                Button("CMYK") {
                    NSPasteboard.copy(
                        String(
                            format: "cmyk(%1$.0f%%, %2$.0f%%, %3$.0f%%, %4$.0f%%)",
                            color.cmyk.cyan * 100, color.cmyk.magenta * 100, color.cmyk.yellow * 100, color.cmyk.key * 100
                        )
                    )
                }
                
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
