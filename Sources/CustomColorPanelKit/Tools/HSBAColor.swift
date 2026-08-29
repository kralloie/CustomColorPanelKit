//
//  HSBAColor.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import Foundation
import SwiftUI

struct HSBAColor: Equatable, Hashable {
    var hue:        CGFloat { didSet { if hue        != oldValue { storedKey = nil } } }
    var saturation: CGFloat { didSet { if saturation != oldValue { storedKey = nil } } }
    var brightness: CGFloat { didSet { if brightness != oldValue { storedKey = nil } } }
    
    var alpha: CGFloat
    private var storedKey: CGFloat? = nil
    
    public init(with color: Color) {
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            
            rgbColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            
            self.hue = h
            self.saturation = (b == 0) ? 1 : s
            self.brightness = b
            self.alpha = a
        } else {
            self.hue = 0.0
            self.saturation = 0.0
            self.brightness = 1.0
            self.alpha = 1.0
        }
    }
    
    public init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat = 1) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }
    
    var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha) }
    
    var rgb: RGB {
        get {
            let h = hue
            let s = saturation.clamped(to: 0...1)
            let v = brightness.clamped(to: 0...1)

            let h6 = h * 6
            let i = Int(floor(h6)) % 6
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
    
    var hsl: HSL {
        get {
            let s_hsb = saturation.clamped(to: 0...1)
            let b_hsb = brightness.clamped(to: 0...1)
            let lightness = b_hsb * (1.0 - (s_hsb / 2))
            var s_hsl: Double = 0.0
            if lightness > 0.0 && lightness < 1.0 {
                s_hsl = (b_hsb - lightness) / min(lightness, 1.0 - lightness)
            }
            
            return HSL(hue: hue, saturation: s_hsl, lightness: lightness)
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
            self.storedKey = k // must be asigned last always
        }
    }
    
    var hsvString: String {
        let h = InputType.degrees.format(hue)
        let s = InputType.percentage.format(saturation)
        let v = InputType.percentage.format(brightness)
        return String("\(h), \(s), \(v)")
    }
    
    var hexString: String { String(format: "#%06X", hex) }
    
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

struct HSL {
    var hue: CGFloat
    var saturation: CGFloat
    var lightness: CGFloat
    
    var string: String {
        let h = InputType.degrees.format(hue)
        let s = InputType.percentage.format(saturation)
        let l = InputType.percentage.format(lightness)
        return String("\(h), \(s), \(l)")
    }
}

struct RGB {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    
    var string: String {
        let r = InputType.numerical.format(red)
        let g = InputType.numerical.format(green)
        let b = InputType.numerical.format(blue)
        return String("\(r), \(g), \(b)")
    }
}

struct CMYK {
    var cyan: CGFloat
    var magenta: CGFloat
    var yellow: CGFloat
    var key: CGFloat
    
    var string: String {
        let c = InputType.percentage.format(cyan)
        let m = InputType.percentage.format(magenta)
        let y = InputType.percentage.format(yellow)
        let k = InputType.percentage.format(key)
        return String("\(c), \(m), \(y), \(k)")
    }
}

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
    init(value: CGFloat) { self = UInt32(value) }
}

private func rgbToHSV(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
    let maxV = max(r, g, b)
    let minV = min(r, g, b)
    let delta = maxV - minV

    let brightness = maxV
    let saturation = maxV == 0 ? 0 : delta / maxV

    var hue: CGFloat = 0
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
