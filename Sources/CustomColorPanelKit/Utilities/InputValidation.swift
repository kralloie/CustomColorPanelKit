//
//  InputValidation.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 30/06/2026.
//

import CoreFoundation

/// The input representation of a color component, used for validating input in text fields and formatting components to strings.
///
/// - Hex: "#FFFFFF"
/// - Degrees: "359°"
/// - Percentage: "100%"
/// - Numerical: "255"
enum InputType {
    /// The available color component formats.
    case hex, degrees, percentage, numerical
    
    /// A multiplier used for normalizing and for single unit steps in controls.
    var multiplier: Int {
        switch self {
        case .degrees: 360
        case .percentage: 100
        case .numerical: 255
        case .hex: 1
        }
    }
    
    /// Returns a formatted string representation of a color component.
    ///
    /// - Parameter value: The value to be formatted into a string.
    func format(_ value: CGFloat) -> String {
        switch self {
        case .hex:
            return String(format: "#%06X", UInt32(value))
        case .degrees:
            return "\(min(Int((value * 360).rounded()), 359))°"
        case .percentage:
            return "\(Int((value * 100).rounded()))%"
        case .numerical:
            return "\(Int((value * 255).rounded()))"
        }
    }
    
    /// Returns the integer value from a string if the text matches the regex otherwise returns `nil`.
    ///
    /// - Parameter text: The string to parse.
    func parse(_ text: String) -> Int? {
        switch self {
        case .hex:
            guard let match = text.firstMatch(of: /^#?([0-9A-Fa-f]{6})$/) else { return nil }
            return Int(match.1, radix: 16)
        default:
            guard let match = text.firstMatch(of: /^(-?\d+)[%°]?$/) else { return nil }
            return Int(match.1)
        }
    }
    
    /// Parses a string into a normalized color component value.
    ///
    /// - Returns: A value in `0...1` for degrees, percentages,
    ///   and numerical components, or a 24-bit integer value
    ///   for hexadecimal colors. Returns `nil` if parsing fails.
    ///
    /// - Parameter text: The string to parse and normalize.
    func normalize(_ text: String) -> CGFloat? {
        switch self {
        case .degrees:
            if let match = parse(text) {
                let wrapped = ((match % 360) + 360) % 360
                return CGFloat(wrapped) / 360
            }
        case .percentage:
            if let match = parse(text)?.clamped(to: 0...100) {
                return CGFloat(match) / 100
            }
        case .numerical:
            if let match = parse(text)?.clamped(to: 0...255) {
                return CGFloat(match) / 255
            }
        case .hex:
            if let match = text.firstMatch(of: /^#?([0-9A-Fa-f]{6})$/) {
                if let n = UInt32(match.1, radix: 16) {
                    return CGFloat(n)
                }
            }
        }
        return nil
    }
}
