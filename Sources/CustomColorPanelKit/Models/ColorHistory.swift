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
    
    /// Creates an empty history.
    init() { colors.reserveCapacity(Self.capacity) }
    
    /// Adds a color to the front of the history.
    ///
    /// - Parameter color: The color to add.
    func add(_ color: HSBAColor) {
        if let first = colors.first, first ≈≈ color { return }
        
        if let index = isStored(color) {
            colors.remove(at: index)
        }
        
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
    func clear() { colors.removeAll(keepingCapacity: true) }
    
    /// Returns an index if the color is already stored on the history, returns `nil` if it is not.
    ///
    /// - Parameter color: The color to be checked whether it is currently on the history.
    func isStored(_ color: HSBAColor) -> Int? {
        return colors.firstIndex(where: { c in c ≈≈ color })
    }
    
    /// Returns the color at the specified index, or `nil` if the
    /// index is outside the history's bounds.
    ///
    /// - Parameter index: The index of the color to retrieve.
    subscript(safe index: Int) -> HSBAColor? {
        return colors.indices.contains(index) ? colors[index] : nil
    }
}
