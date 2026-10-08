//
//  ColorHistory.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

/// A most-recently-used list of the picked colors.
///
/// The newest color comes first.
/// When the history is full, adding a color removes the oldest one.
@Observable
final class ColorHistory {
    /// The most colors the history keeps.
    static let capacity = 144
    
    /// The stored colors, newest first.
    private(set) var colors: [HSBAColor] = []
    /// A color chosen from the history that the color panel hasn't applied yet.
    ///
    /// Set when someone picks a swatch. The panel applies the color and then sets
    /// this back to `nil`.
    var pendingChange: HSBAColor?
    
    /// Creates an empty history.
    init() { colors.reserveCapacity(Self.capacity) }
    
    /// Adds a color to the front of the history.
    ///
    /// - Parameter color: The color to add.
    func add(_ color: HSBAColor) {
        
        if let index = isStored(color) { colors.remove(at: index) }
        
        if colors.count == Self.capacity { colors.removeLast(); }
        
        colors.insert(color, at: 0)
    }
    
    /// Removes a color from the history.
    ///
    /// - Parameter color: The color to remove.
    func delete(_ color: HSBAColor) {
        if let index = isStored(color) {
            colors.remove(at: index)
        }
    }
    
    /// Removes every color from the history.
    func clear() { colors.removeAll() }
    
    /// Returns an index if the color is already stored on the history, returns `nil` if it is not.
    ///
    /// - Parameter color: The color to be checked whether it is currently on the history.
    func isStored(_ color: HSBAColor) -> Int? {
        return colors.firstIndex(where: { c in
            c.hue == color.hue && c.saturation == color.saturation && c.brightness == color.brightness && c.alpha == color.alpha
        })
    }
}
