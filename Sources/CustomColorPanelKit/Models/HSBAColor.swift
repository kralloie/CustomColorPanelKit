//
//  HSBAColor.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import Foundation
import SwiftUI

infix operator ≈≈ : ComparisonPrecedence

/// A color stored as hue, saturation, brightness and alpha, with conversions to RGB, hex, HSL and CMYK.
///
/// The stored components are expected to be in `0...1`. Hue is a fraction of a full turn, so `0` and `1`
/// are both red. The other models are computed from these values, and setting one updates the stored
/// values. None of them change alpha.
///
/// Equality and hashing compare only the four stored components. The remembered CMYK key
/// (see ``cmyk``) is ignored, so two colors that differ only in it are equal.
struct HSBAColor: Equatable, Hashable {
    /// The hue as a fraction of a full turn.
    ///
    /// The RGB conversion wraps values outside `0...1`. Changing it discards the remembered CMYK key,
    /// but assigning the value it already has doesn't.
    var hue:        CGFloat { didSet { if hue        != oldValue { storedKey = nil } } }
    /// The saturation. Changing it discards the remembered CMYK key.
    var saturation: CGFloat { didSet { if saturation != oldValue { storedKey = nil } } }
    /// The brightness. Changing it discards the remembered CMYK key.
    var brightness: CGFloat { didSet { if brightness != oldValue { storedKey = nil } } }
    
    /// The opacity, from 0 (transparent) to 1 (opaque).
    var alpha: CGFloat
    /// The key last set through ``cmyk``, or `nil` if none is remembered.
    ///
    /// Changing the hue, saturation or brightness clears it, so the ``cmyk`` setter assigns it after them.
    private var storedKey: CGFloat? = nil
    
    /// Creates a color from a SwiftUI color.
    ///
    /// The color is converted through sRGB. If that conversion fails, the result is opaque white.
    ///
    /// - Parameter color: The color to convert.
    init(with color: Color) {
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            
            rgbColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            
            self.hue = h
            self.saturation = (b == 0) ? 0 : s
            self.brightness = b
            self.alpha = a
        } else {
            self.hue = 0.0
            self.saturation = 0.0
            self.brightness = 1.0
            self.alpha = 1.0
        }
    }
    
    /// Creates a color from its components.
    ///
    /// The values aren't clamped, so pass components in `0...1`.
    ///
    /// - Parameters:
    ///   - hue: The hue as a fraction of a full turn.
    ///   - saturation: The saturation.
    ///   - brightness: The brightness.
    ///   - alpha: The opacity. Defaults to 1.
    init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat = 1) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }
    
    /// Creates a color from an NSColor
    ///
    /// The color is converted through sRGB. If that conversion fails, the result is opaque white.
    ///
    /// - Parameter nsColor: The color to convert.
    init(with nsColor: NSColor) {
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            self.init(hue: 0, saturation: 0, brightness: 1)
            return
        }

        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        rgbColor.getHue(
            &h,
            saturation: &s,
            brightness: &b,
            alpha: &a
        )

        self.init(
            hue: h,
            saturation: b == 0 ? 0 : s,
            brightness: b,
            alpha: a
        )
    }
    
    /// The color as a SwiftUI `Color`.
    var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha) }
    
    /// The color as a `NSColor`.
    var nsColor: NSColor {
        let rgb = rgb
        return NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: alpha)
    }
    
    /// The color as red, green and blue channels, each from 0 to 1.
    var rgb: RGB {
        get {
            let h = hue
            let s = saturation.clamped(to: 0...1)
            let v = brightness.clamped(to: 0...1)

            let h6 = h * 6
            let i = ((Int(floor(h6)) % 6) + 6) % 6
            let f = h6 - floor(h6)

            let p = v * (1 - s)
            let q = v * (1 - s * f)
            let t = v * (1 - s * (1 - f))

            let r: CGFloat, g: CGFloat, b: CGFloat

            switch i {
            case 0: (r, g, b) = (v, t, p)
            case 1: (r, g, b) = (q, v, p)
            case 2: (r, g, b) = (p, v, t)
            case 3: (r, g, b) = (p, q, v)
            case 4: (r, g, b) = (t, p, v)
            default: (r, g, b) = (v, p, q)
            }

            return RGB(red: r, green: g, blue: b)
        }
        
        set {
            let hsv = rgbToHSV(
                newValue.red.clamped(to: 0...1),
                newValue.green.clamped(to: 0...1),
                newValue.blue.clamped(to: 0...1)
            )
            self.hue = hsv.hue
            self.saturation = hsv.saturation
            self.brightness = hsv.brightness
        }
    }
    
    /// The color as a 24-bit `0xRRGGBB` value, rounded to 8 bits per channel.
    ///
    /// Alpha isn't part of the value. Setting it ignores bits above the lowest 24 and updates the hue,
    /// saturation and brightness the same way setting ``rgb`` does.
    /// Colors that differ by less than one 8-bit step share a hex value.
    var hex: UInt32 {
        get {
            let rgb = self.rgb
            let r = UInt32((rgb.red.clamped(to: 0...1) * 255).rounded())
            let g = UInt32((rgb.green.clamped(to: 0...1) * 255).rounded())
            let b = UInt32((rgb.blue.clamped(to: 0...1) * 255).rounded())
            
            return (r << 16) | (g << 8) | b
        }
        
        set {
            let value = newValue & 0xFFFFFF
            let r = CGFloat(value >> 16 & 0xff) / 255
            let g = CGFloat(value >> 8 & 0xff) / 255
            let b = CGFloat(value & 0xff) / 255
            
            let hsv = rgbToHSV(r, g, b)
            self.hue = hsv.hue
            self.saturation = hsv.saturation
            self.brightness = hsv.brightness
        }
    }
    
    /// The color as hue, saturation and lightness, each from 0 to 1.
    var hsl: HSL {
        get {
            let sHsv = saturation.clamped(to: 0...1)
            let bHsv = brightness.clamped(to: 0...1)
            let lightness = bHsv * (1.0 - (sHsv / 2))
            var sHsl: CGFloat = 0.0
            if lightness > 0.0 && lightness < 1.0 {
                sHsl = (bHsv - lightness) / min(lightness, 1.0 - lightness)
            }
            
            return HSL(hue: hue, saturation: sHsl, lightness: lightness)
        }
        
        set {
            let h = newValue.hue.clamped(to: 0...1)
            let s = newValue.saturation.clamped(to: 0...1)
            let l = newValue.lightness.clamped(to: 0...1)
            let brightness = l + s * min(l, 1 - l)
            let saturation = brightness == 0 ? 0 : 2 * (1 - l / brightness)
            self.hue = h
            self.saturation = saturation.clamped(to: 0...1)
            self.brightness = brightness.clamped(to: 0...1)
        }
    }

    /// The color as cyan, magenta, yellow and key channels, each from 0 to 1.
    ///
    /// Many CMYK values describe the same color, so the key can't be derived from RGB alone. The key
    /// most recently set through this property is remembered and read back, with cyan, magenta and
    /// yellow computed from it. Changing the hue, saturation or brightness discards the remembered
    /// key, and the key then becomes the largest one the color allows.
    ///
    /// At a key of 1 the color is black, so the other channels read as 0.
    var cmyk: CMYK {
        get {
            let rgb = self.rgb
            let maxV = max(rgb.red, rgb.green, rgb.blue)
            let maxK = 1 - maxV
            let k = (storedKey ?? maxK).clamped(to: 0...maxK)

            guard k < 1 else { return CMYK(cyan: 0, magenta: 0, yellow: 0, key: 1) }
            let inv = 1 - k
            let c = ((1 - rgb.red   - k) / inv).clamped(to: 0...1)
            let m = ((1 - rgb.green - k) / inv).clamped(to: 0...1)
            let y = ((1 - rgb.blue  - k) / inv).clamped(to: 0...1)
            return CMYK(cyan: c, magenta: m, yellow: y, key: k)
        }
        
        set {
            let c = newValue.cyan.clamped(to: 0...1)
            let m = newValue.magenta.clamped(to: 0...1)
            let y = newValue.yellow.clamped(to: 0...1)
            let k = newValue.key.clamped(to: 0...1)

            let r = (1 - c) * (1 - k)
            let g = (1 - m) * (1 - k)
            let b = (1 - y) * (1 - k)

            let hsv = rgbToHSV(r, g, b)
            self.hue = hsv.hue
            self.saturation = hsv.saturation
            self.brightness = hsv.brightness
            self.storedKey = k
        }
    }
    
    /// The hue, saturation and brightness formatted for display, such as `"359°, 74%, 100%"`.
    var hsvString: String {
        let h = InputType.degrees.format(hue)
        let s = InputType.percentage.format(saturation)
        let v = InputType.percentage.format(brightness)
        return "\(h), \(s), \(v)"
    }
    
    /// The hex value as a string with a leading `#`, such as `"#FF4245"`.
    var hexString: String { String(format: "#%06X", hex) }
    
    /// Converts red, green and blue channels to hue, saturation and brightness.
    ///
    /// Hue is undefined for grays, so the color's current hue is returned instead (this reads `self`).
    /// Saturation is 0 for grays and black.
    /// - Parameters:
    ///   - r: The red channel, from 0 to 1.
    ///   - g: The green channel, from 0 to 1.
    ///   - b: The blue channel, from 0 to 1.
    /// - Returns: The hue as a fraction of a full turn, and the saturation and brightness, each from 0 to 1.
    private func rgbToHSV(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        let maxV = max(r, g, b)
        let minV = min(r, g, b)
        let delta = maxV - minV

        let brightness = maxV
        let saturation = maxV == 0 ? 0 : delta / maxV

        var hue: CGFloat = self.hue
        if delta != 0 {
            switch maxV {
            case r: hue = (g - b) / delta
            case g: hue = (b - r) / delta + 2
            default: hue = (r - g) / delta + 4
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }

        return (hue, saturation, brightness)
    }
    
    /// An item provider containing the color's native macOS color representation.
    var dragItemProvider: NSItemProvider {
        let color = nsColor

        guard let propertyList = color.pasteboardPropertyList(
            forType: .color
        ) else {
            return NSItemProvider()
        }

        return NSItemProvider(
            item: propertyList as? NSSecureCoding,
            typeIdentifier: NSPasteboard.PasteboardType.color.rawValue
        )
    }
    
    /// The tolerance used for comparing colors.
    private static let epsilon = 1.0 / 512.0
    
    /// Returns whether two colors are visually equivalent within ``epsilon``.
    static func ≈≈ (a: Self, b: Self) -> Bool {
        let lhs = a.rgb
        let rhs = b.rgb

        return abs(lhs.red - rhs.red) < epsilon &&
               abs(lhs.green - rhs.green) < epsilon &&
               abs(lhs.blue - rhs.blue) < epsilon &&
               abs(a.alpha - b.alpha) < epsilon
    }
    
    static func == (a: Self, b: Self) -> Bool {
        a.hue == b.hue && a.saturation == b.saturation && a.brightness == b.brightness && a.alpha == b.alpha
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hue)
        hasher.combine(saturation)
        hasher.combine(brightness)
        hasher.combine(alpha)
    }
}

/// A color as hue, saturation and lightness, each from 0 to 1.
struct HSL {
    var hue: CGFloat
    var saturation: CGFloat
    var lightness: CGFloat
    
    /// The components formatted for display, such as `"359°, 100%, 63%"`.
    var string: String {
        let h = InputType.degrees.format(hue)
        let s = InputType.percentage.format(saturation)
        let l = InputType.percentage.format(lightness)
        return "\(h), \(s), \(l)"
    }
}

/// A color as red, green and blue channels, each from 0 to 1.
struct RGB {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    
    /// The channels formatted for display, such as `"255, 66, 69"`.
    var string: String {
        let r = InputType.numerical.format(red)
        let g = InputType.numerical.format(green)
        let b = InputType.numerical.format(blue)
        return "\(r), \(g), \(b)"
    }
}

/// A color as cyan, magenta, yellow and key channels, each from 0 to 1.
struct CMYK {
    var cyan: CGFloat
    var magenta: CGFloat
    var yellow: CGFloat
    var key: CGFloat
    
    /// The channels formatted for display, such as `"0%, 74%, 73%, 0%"`.
    var string: String {
        let c = InputType.percentage.format(cyan)
        let m = InputType.percentage.format(magenta)
        let y = InputType.percentage.format(yellow)
        let k = InputType.percentage.format(key)
        return "\(c), \(m), \(y), \(k)"
    }
}

/// A number that a ``ColorComponentField`` can edit, converted to and from a `CGFloat`.
protocol ColorComponentNumeric {
    var cgFloatValue: CGFloat { get }
    init(value: CGFloat)
}

extension CGFloat: ColorComponentNumeric {
    var cgFloatValue: CGFloat { self }
    init(value: CGFloat) { self = value }
}

extension UInt32: ColorComponentNumeric {
    var cgFloatValue: CGFloat { CGFloat(self) }
    /// Creates a value from `value`, truncating toward zero.
    ///
    /// Values below 0 become 0, values above `UInt32.max` become `UInt32.max`, and `NaN` or
    /// infinite values become 0.
    init(value: CGFloat) {
        self = value.isFinite ? UInt32(value.clamped(to: 0...CGFloat(UInt32.max))) : 0
    }
}
