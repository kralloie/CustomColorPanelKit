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
    
    public init(c: Binding<Color>) {
        self._colorBinding = c
        self.color = HSBAColor(with: c.wrappedValue)
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            HueWheelColorPicker(color: $color, antialiasing: false, colorHistory: colorHistory)
                .padding(8)
            ColorValuesView(color: $color, colorHistory: colorHistory)
                .padding(8)
        }
    }
}
