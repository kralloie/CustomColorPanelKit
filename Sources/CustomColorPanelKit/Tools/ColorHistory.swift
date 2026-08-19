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
    private let capacity = 144
    var pendingChange: HSBAColor?
    
    init() { colors.reserveCapacity(capacity) }
    
    func add(_ color: HSBAColor) {
        var color = color
        color.alpha = 1.0
        
        if let index = colors.firstIndex(where: { $0.hex == color.hex }) {
            colors.remove(at: index)
        }
        
        if colors.count == capacity { colors.removeLast() }
        
        colors.insert(color, at: 0)
    }
    
    func delete(_ color: HSBAColor) {
        if let index = colors.firstIndex(where : { $0.hex == color.hex }) {
            colors.remove(at: index)
        }
    }
}
