//
//  PositiveZeroFloat.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import CoreFoundation

extension Double {
    var positiveZero: Double { self == 0 ? 0 : self }
}

extension CGFloat {
    var positiveZero: CGFloat { self == 0 ? 0 : self }
}
