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
    
    var validate: (String) -> CGFloat {
        switch self {
        case .degrees:
            return {
                if let match = $0.firstMatch(of: /^-?(\d+)°?$/) {
                    var n = Int(match.1)!
                    n = n > 360 ? 0 : n < 0 ? 360 : n
                    return CGFloat(min(max(n, 0), 360)) / 360
                } else {
                    return 0
                }
            }
        case .percentage:
            return {
                if let match = $0.firstMatch(of: /^(\d+)%?$/) {
                    let n = Int(match.1)!
                    return CGFloat(min(max(n, 0), 100)) / 100
                } else {
                    return 0
                }
            }
        case .numerical:
            return {
                if let match = $0.firstMatch(of: /^\d+$/) {
                    let n = Int(match.0)!
                    return CGFloat(min(max(n, 0), 255)) / 255
                } else {
                    return 0
                }
            }
        case .hex:
            return {
                if let match = $0.firstMatch(of: /^#?([0-9A-Fa-f]{6})$/) {
                    let hex = String(match.1)
                    let r = Int(hex.prefix(2), radix: 16)!
                    let g = Int(hex.dropFirst(2).prefix(2), radix: 16)!
                    let b = Int(hex.dropFirst(4), radix: 16)!
                    return CGFloat(r << 16 | g << 8 | b)
                } else {
                    return 0
                }
            }
        }
    }
}
