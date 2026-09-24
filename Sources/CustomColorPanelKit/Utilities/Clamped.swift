//
//  Clamped.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 16/07/2026.
//

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
