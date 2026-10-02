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

public struct ColorPanelView: View {
    @Binding var colorBinding: Color
    @State var color: HSBAColor {
        didSet { colorBinding = color.color }
    }
    @State var colorHistory = ColorHistory()
    @State var pickerMode: PickerMode = .hueRing
        
    public init(_ c: Binding<Color>, antialiasing: Bool = true) {
        self._colorBinding = c
        self.color = HSBAColor(with: c.wrappedValue)
    }
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
        } detail : {
            switch pickerMode {
            case .hueRing:
                HueRingPickerView(color: $color, colorHistory: colorHistory)
            case .hsvSquare:
                HSVSquarePickerView(color: $color, colorHistory: colorHistory)
            case .hsvSphere:
                HueSpherePickerView(color: $color, colorHistory: colorHistory)
            }

        }
        .background {
            ScrollWheelMonitor(router: ScrollWheelRouter.shared, color: $color, storeColor: { colorHistory.add($0) })
        }
        .onChange(of: colorHistory.pendingChange) {
            guard var newColor = colorHistory.pendingChange else { return }
            newColor.alpha = color.alpha
            color = newColor
            colorHistory.pendingChange = nil
        }
    }
}
