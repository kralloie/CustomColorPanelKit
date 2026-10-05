//
//  ColorHistory.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

/// A most-recently-used list of the picked colors.
///
/// The newest color comes first. Stored colors are always opaque, and no two share a hex value.
/// When the history is full, adding a color removes the oldest one.
///
/// The colors are compared by their hex value when deleted or checked for repetition.
@Observable
final class ColorHistory {
    /// The stored colors, newest first.
    private(set) var colors: [HSBAColor] = []
    /// The hex value of each color in ``colors``, in the same order.
    ///
    /// Used to find duplicates without comparing every color. It must always have the same length as ``colors``.
    private var hexes: [UInt32] = []
    /// The most colors the history keeps.
    private let capacity = 144
    /// A color chosen from the history that the color panel hasn't applied yet.
    ///
    /// Set when someone picks a swatch. The panel applies the color, keeping its own
    /// alpha because stored colors are opaque, and then sets this back to `nil`.
    var pendingChange: HSBAColor?
    
    /// Creates an empty history.
    init() { colors.reserveCapacity(capacity) }
    
    /// Adds a color to the front of the history.
    ///
    /// All colors are stored with the alpha of 1.
    ///
    /// - Parameter color: The color to add. Its alpha is ignored.
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
    
    /// Removes a color from the history.
    ///
    /// Colors are matched by hex value, so the alpha is ignored. Does nothing if no stored color matches.
    ///
    /// - Parameter color: The color to remove.
    func delete(_ color: HSBAColor) {
        let hex = color.hex
        if let index = hexes.firstIndex(of: hex) {
            colors.remove(at: index)
            hexes.remove(at: index)
        }
    }
    
    /// Removes every color from the history.
    func clear() {
        colors.removeAll()
        hexes.removeAll()
    }
}
