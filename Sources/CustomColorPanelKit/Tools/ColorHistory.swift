//
//  ColorHistory.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

@Observable
final class ColorHistory {
    var colors: [HSBAColor] = []
    private let maxCapacity = 144
    
    init() { colors.reserveCapacity(maxCapacity) }
    
    func add(_ color: HSBAColor) {
        if let index = colors.firstIndex(where: { $0.hex == color.hex }) {
            colors.remove(at: index)
        }
        
        if colors.count == maxCapacity { colors.removeLast() }
        
        var c = color
        c.alpha = 1.0
        colors.insert(c, at: 0)
    }
}
