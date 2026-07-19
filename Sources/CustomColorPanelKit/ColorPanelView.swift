//
//  ColorPanelView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

public struct ColorPanelView: View {
    @Binding var colorBinding: Color
    @State var color: HSBAColor {
        didSet { colorBinding = color.color }
    }
    @State var colorHistory = ColorHistory()
    var sidebarAligment: SidebarAlignment
    
    public init(_ c: Binding<Color>, sidebarAlignment: SidebarAlignment = .leading) {
        self._colorBinding = c
        self.color = HSBAColor(with: c.wrappedValue)
        self.sidebarAligment = sidebarAlignment
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            if sidebarAligment == .leading {
                ColorValuesView(alignment: .leading, color: $color, colorHistory: colorHistory)
                    .padding(8)
                HueRingPickerView(color: $color, colorHistory: colorHistory)
                    .padding(8)
            } else {
                HueRingPickerView(color: $color, colorHistory: colorHistory)
                    .padding(8)
                ColorValuesView(alignment: .trailing, color: $color, colorHistory: colorHistory)
                    .padding(8)
            }
        }
    }
}

extension ColorPanelView {
    public enum SidebarAlignment {
        case leading, trailing
    }
}
