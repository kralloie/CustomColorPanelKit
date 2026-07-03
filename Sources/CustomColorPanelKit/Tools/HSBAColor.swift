//
//  HSBAColor.swift
//  CustomColorPanel
//
//  Created by Franco Gargiulo on 06/06/2026.
//

import Foundation
import SwiftUI

public struct HSBAColor: Equatable, Hashable {
    var hue: CGFloat
    var saturation: CGFloat
    var brightness: CGFloat
    var alpha: CGFloat
    
    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }
    
    var rgb: RGB {
        get {
            let h = hue * 6
            let i = Int(floor(h)) % 6
            let f = h - floor(h)
            let p = brightness * (1 - saturation)
            let q = brightness * (1 - saturation * f)
            let t = brightness * (1 - saturation * (1 - f))

            let r: CGFloat, g: CGFloat, b: CGFloat
            switch i {
            case 0: (r, g, b) = (brightness, t, p)
            case 1: (r, g, b) = (q, brightness, p)
            case 2: (r, g, b) = (p, brightness, t)
            case 3: (r, g, b) = (p, q, brightness)
            case 4: (r, g, b) = (t, p, brightness)
            default: (r, g, b) = (brightness, p, q)
            }
            return RGB(red: r, green: g, blue: b)
        }
        
        set {
            print(newValue)
            let color = Color(red: newValue.red, green: newValue.green, blue: newValue.blue)
            self = HSBAColor(with: color)
        }
    }
    
    var hex: UInt32 {
        get {
            let r = UInt32((rgb.red * 255).rounded())
            let g = UInt32((rgb.green * 255).rounded())
            let b = UInt32((rgb.blue * 255).rounded())
            
            return (r << 16) | (g << 8) | b
        }
        
        set {
            let r = CGFloat(newValue >> 16 & 0xff) / 255
            let g = CGFloat(newValue >> 8 & 0xff) / 255
            let b = CGFloat(newValue & 0xff) / 255
            
            let color = Color(red: r, green: g, blue: b)
            self = HSBAColor(with: color)
        }
    }
    
    var hsl: HSL {
        get {
            let s_hsb = max(0.0, min(1.0, saturation))
            let b_hsb = max(0.0, min(1.0, brightness))
            let lightness = brightness * (1.0 - (s_hsb / 2))
            var s_hsl: Double = 0.0
            if lightness > 0.0 && lightness < 1.0 {
                s_hsl = (b_hsb - lightness) / min(lightness, 1.0 - lightness)
            }
            
            return HSL(hue: hue, saturation: s_hsl, lightness: lightness)
        }
        
        set {
            let (h, s, l) = (newValue.hue, newValue.saturation, newValue.lightness)
            let brightness = l + s * min(l, 1 - l)
            let saturation = brightness == 0 ? 0 : 2 * (1 - l / brightness)
            self.hue = h
            self.saturation = saturation
            self.brightness = brightness
        }
    }

    var cmyk: CMYK {
        get {
            let k = 1 - max(rgb.red, rgb.green, rgb.blue)

            guard k < 1 else { return CMYK(cyan: 0, magenta: 0, yellow: 0, key: 1) }
            let c = (1 - rgb.red - k) / (1 - k)
            let m = (1 - rgb.green - k) / (1 - k)
            let y = (1 - rgb.blue - k) / (1 - k)
            return CMYK(cyan: c, magenta: m, yellow: y, key: k)
        }
        
        set {
            let r = (1 - newValue.cyan) * (1 - newValue.key)
            let g = (1 - newValue.magenta) * (1 - newValue.key)
            let b = (1 - newValue.yellow) * (1 - newValue.key)
            let color = Color(red: r, green: g, blue: b)
            self = HSBAColor(with: color)
        }
    }
    
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
}

struct HSL {
    var hue: CGFloat
    var saturation: CGFloat
    var lightness: CGFloat
}

struct RGB {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
}

struct CMYK {
    var cyan: CGFloat
    var magenta: CGFloat
    var yellow: CGFloat
    var key: CGFloat
}

