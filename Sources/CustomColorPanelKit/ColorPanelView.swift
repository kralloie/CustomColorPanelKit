//
//  ColorPanelView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

enum PickerMode: Int, CaseIterable {
    case hueRing, hsvSquare, hsvSphere
    
    var string: String {
        switch self {
            case .hueRing: return "Hue Ring"
            case .hsvSquare: return "HSV Square"
            case .hsvSphere: return "HSV Sphere"
        }
    }
}

public struct ColorPanelView: View {
    @Binding var colorBinding: Color
    @State var color: HSBAColor {
        didSet { colorBinding = color.color }
    }
    @State var colorHistory = ColorHistory()
    @State var pickerMode: PickerMode = .hsvSquare
    var sidebarAligment: SidebarAlignment
    var antialiasing: Bool
    
    public init(_ c: Binding<Color>, sidebarAlignment: SidebarAlignment = .leading, antialiasing: Bool = true) {
        self._colorBinding = c
        self.color = HSBAColor(with: c.wrappedValue)
        self.sidebarAligment = sidebarAlignment
        self.antialiasing = antialiasing
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            if sidebarAligment == .leading {
                ColorValuesView(alignment: .leading, color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
                
                switch pickerMode {
                case .hueRing:
                    HueRingPickerView(color: $color, antialiasing: antialiasing, colorHistory: colorHistory)
                case .hsvSquare:
                    HSVSquarePickerView(color: $color, colorHistory: colorHistory, sidebarAlignment: sidebarAligment)
                case .hsvSphere:
                    HSVSpherePickerView(color: $color, colorHistory: colorHistory, antialiasing: antialiasing)
                }
                
            } else {
                switch pickerMode {
                case .hueRing:
                    HueRingPickerView(color: $color, antialiasing: antialiasing, colorHistory: colorHistory)
                case .hsvSquare:
                    HSVSquarePickerView(color: $color, colorHistory: colorHistory, sidebarAlignment: sidebarAligment)
                case .hsvSphere:
                    HSVSpherePickerView(color: $color, colorHistory: colorHistory, antialiasing: antialiasing)
                }
                
                ColorValuesView(alignment: .trailing, color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
            }
        }
    }
}

public enum SidebarAlignment {
    case leading, trailing
}
