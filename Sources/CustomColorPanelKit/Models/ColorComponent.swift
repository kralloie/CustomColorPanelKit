//
//  Component.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 10/10/2026.
//

import SwiftUI

/// Describes a color component displayed and edited by the sidebar.
@MainActor
struct ColorComponent<Value: ColorComponentNumeric> {
    /// The short symbol displayed next to the component, if any.
    let symbol: String?

    /// The key path used to read and modify the component.
    let keyPath: WritableKeyPath<HSBAColor, Value>

    /// The input format used to display and edit the component.
    let inputType: InputType

    /// The localized accessibility label for the component.
    let label: LocalizedStringResource
}

extension ColorComponent where Value == UInt32 {
    static let hex = Self(
        symbol: nil,
        keyPath: \.hex,
        inputType: .hex,
        label: .componentHex
    )
}

extension ColorComponent where Value == CGFloat {
    static let alpha = Self(
        symbol: nil,
        keyPath: \.alpha,
        inputType: .percentage,
        label: .componentAlpha
    )

    // MARK: - HSV

    static let hsvHue = Self(
        symbol: "H",
        keyPath: \.hue,
        inputType: .degrees,
        label: .componentHue
    )

    static let hsvSaturation = Self(
        symbol: "S",
        keyPath: \.saturation,
        inputType: .percentage,
        label: .componentSaturation
    )

    static let brightness = Self(
        symbol: "V",
        keyPath: \.brightness,
        inputType: .percentage,
        label: .componentBrightness
    )

    // MARK: - HSL

    static let hslHue = Self(
        symbol: "H",
        keyPath: \.hsl.hue,
        inputType: .degrees,
        label: .componentHue
    )

    static let hslSaturation = Self(
        symbol: "S",
        keyPath: \.hsl.saturation,
        inputType: .percentage,
        label: .componentSaturation
    )

    static let lightness = Self(
        symbol: "L",
        keyPath: \.hsl.lightness,
        inputType: .percentage,
        label: .componentLightness
    )

    // MARK: - RGB

    static let red = Self(
        symbol: "R",
        keyPath: \.rgb.red,
        inputType: .numerical,
        label: .componentRed
    )

    static let green = Self(
        symbol: "G",
        keyPath: \.rgb.green,
        inputType: .numerical,
        label: .componentGreen
    )

    static let blue = Self(
        symbol: "B",
        keyPath: \.rgb.blue,
        inputType: .numerical,
        label: .componentBlue
    )

    // MARK: - CMYK

    static let cyan = Self(
        symbol: "C",
        keyPath: \.cmyk.cyan,
        inputType: .percentage,
        label: .componentCyan
    )

    static let magenta = Self(
        symbol: "M",
        keyPath: \.cmyk.magenta,
        inputType: .percentage,
        label: .componentMagenta
    )

    static let yellow = Self(
        symbol: "Y",
        keyPath: \.cmyk.yellow,
        inputType: .percentage,
        label: .componentYellow
    )

    static let black = Self(
        symbol: "K",
        keyPath: \.cmyk.key,
        inputType: .percentage,
        label: .componentBlack
    )
}
