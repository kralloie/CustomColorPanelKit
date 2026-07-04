//
//  ColorHistoryView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 26/06/2026.
//

import SwiftUI

struct ColorHistoryView: View {
    @Binding var color: HSBAColor
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
    
    @State var hoveredIndex: Int? = nil
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: spacing) {
            ForEach(0..<(columns * columns), id: \.self) { i in
                ColorHistoryEntry(color: $color, hoveredIndex: $hoveredIndex, index: i, colorSize: colorSize, colorHistory: colorHistory)
            }
        }
        .frame(width: frameSize, height: frameSize)
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        }
        .overlay { hoverTooltip }
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private var hoverTooltip: some View {
        if let index = hoveredIndex {
            let cellStep = colorSize + spacing
            Text(String(format: "#%06X", colorHistory.colors[index].hex))
                .font(.system(size: 11, design: .monospaced))
                .padding(2)
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 4))
                .fixedSize()
                .allowsHitTesting(false)
                .position(
                    x: cellStep * CGFloat(index).truncatingRemainder(dividingBy: 12) + cellStep,
                    y: 14 * CGFloat(index / 12) - cellStep * 0.5
                )
        } else {
            EmptyView()
        }
    }
    
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
                    .scaleEffect(isHovering ? 1.5 : 1)
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
                    .frame(width: colorSize, height: colorSize)
            }
        }
    }
}
