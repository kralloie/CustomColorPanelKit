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
    @State var pickerMode: PickerMode = .hueRing
    var sidebarAligment: SidebarAlignment
    
    public init(_ c: Binding<Color>, sidebarAlignment: SidebarAlignment = .leading, antialiasing: Bool = true) {
        self._colorBinding = c
        self.color = HSBAColor(with: c.wrappedValue)
        self.sidebarAligment = sidebarAlignment
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            if sidebarAligment == .leading {
                SidebarView(alignment: .leading, color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
                
                switch pickerMode {
                case .hueRing:
                    HueRingPickerView(color: $color, colorHistory: colorHistory)
                case .hsvSquare:
                    HSVSquarePickerView(color: $color, colorHistory: colorHistory, sidebarAlignment: sidebarAligment)
                case .hsvSphere:
                    HSVSpherePickerView(color: $color, colorHistory: colorHistory)
                }
                
            } else {
                switch pickerMode {
                case .hueRing:
                    HueRingPickerView(color: $color, colorHistory: colorHistory)
                case .hsvSquare:
                    HSVSquarePickerView(color: $color, colorHistory: colorHistory, sidebarAlignment: sidebarAligment)
                case .hsvSphere:
                    HSVSpherePickerView(color: $color, colorHistory: colorHistory)
                }
                
                SidebarView(alignment: .trailing, color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
            }
        }
    }
}

public enum SidebarAlignment {
    case leading, trailing
}
