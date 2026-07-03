//
//  StripNegativeZero.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import CoreFoundation

extension String {
    var strippingNegativeZero: String {
        guard self.hasPrefix("-") else { return self }
        let numericPrefix = self.dropFirst().prefix { $0.isNumber || $0 == "." }
        if let value = Double(numericPrefix), value == 0 {
            return String(self.dropFirst())
        }
        return self
    }
}
