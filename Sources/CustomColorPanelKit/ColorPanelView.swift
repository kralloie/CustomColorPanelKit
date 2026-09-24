//
//  ColorPanelView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

enum PickerMode: Int, CaseIterable, Hashable {
    case hueRing, hsvSquare, hsvSphere
    
    var string: String {
        switch self {
            case .hueRing: return "Hue Ring"
            case .hsvSquare: return "HSV Square"
            case .hsvSphere: return "HSV Sphere"
        }
    }
}

public enum SidebarAlignment {
    case leading, trailing
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
            }
            
            switch pickerMode {
            case .hueRing:
                HueRingPickerView(color: $color, colorHistory: colorHistory)
            case .hsvSquare:
                HSVSquarePickerView(color: $color, colorHistory: colorHistory)
            case .hsvSphere:
                HSVSpherePickerView(color: $color, colorHistory: colorHistory)
            }
            
            if sidebarAligment == .trailing {
                SidebarView(alignment: .trailing, color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
            }
        }
        .background { ScrollWheelMonitor(router: ScrollWheelRouter.shared, storeColor: { colorHistory.add(color) }) }
        .onChange(of: colorHistory.pendingChange) {
            guard var newColor = colorHistory.pendingChange else { return }
            newColor.alpha = color.alpha
            color = newColor
            colorHistory.pendingChange = nil
        }
    }
}
