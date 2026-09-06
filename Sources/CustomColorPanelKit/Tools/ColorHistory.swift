//
//  ColorHistory.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

@Observable
final class ColorHistory {
    private(set) var colors: [HSBAColor] = []
    private var hexes: [UInt32] = []
    private let capacity = 144
    var pendingChange: HSBAColor?
    
    init() { colors.reserveCapacity(capacity) }
    
    func add(_ color: HSBAColor) {
        var color = color
        color.alpha = 1.0
        let hex = color.hex
        
        if let index = hexes.firstIndex(of: hex ) {
            colors.remove(at: index)
            hexes.remove(at: index)
        }
        
        if colors.count == capacity { colors.removeLast(); hexes.removeLast() }
        
        colors.insert(color, at: 0)
        hexes.insert(hex, at: 0)
    }
    
    func delete(_ color: HSBAColor) {
        let hex = color.hex
        if let index = hexes.firstIndex(of: hex) {
            colors.remove(at: index)
        }
    }
}
