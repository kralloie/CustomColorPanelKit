//
//  Clamped.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 16/07/2026.
//

extension Comparable {
    /// Returns the value limited to the bounds of a closed range.
    ///
    /// - Parameter range: The closed range to limit the value to.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
