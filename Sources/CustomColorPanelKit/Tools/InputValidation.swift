//
//  InputValidation.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 30/06/2026.
//

import CoreFoundation

enum InputType {
    case hex, degrees, percentage, numerical
    
    var format: String {
        switch self {
        case .degrees: "%.0f°"
        case .percentage: "%.0f%%"
        case .numerical: "%.0f"
        case .hex: "#%06X"
        }
    }

    
    var multiplier: Int {
        switch self {
        case .degrees: 360
        case .percentage: 100
        case .numerical: 255
        case .hex: 1
        }
    }
    
    func format(_ value: CGFloat) -> String {
        if self == .hex {
            return String(format: format, UInt32(value))
        }
        var v = value * CGFloat(multiplier)
        if self == .degrees { v = min(v, 359) }
        return String(format: format, v)
    }
    
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
    
    func normalize(_ text: String) -> CGFloat {
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
        return 0
    }
}
