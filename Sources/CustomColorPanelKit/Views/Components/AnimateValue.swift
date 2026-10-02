//
//  AnimateValue.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 01/10/2026.
//

import SwiftUI

func animateValue(
    _ value: Binding<CGFloat>,
    to target: CGFloat,
    duration: Duration = .milliseconds(125),
    valueAnimation: Binding<Task<Void, Never>?>
) {
    valueAnimation.wrappedValue?.cancel()
    let start = value.wrappedValue
    let clock = ContinuousClock()
    let begin = clock.now

    valueAnimation.wrappedValue = Task { @MainActor in
        while !Task.isCancelled {
            let t = min(1, (clock.now - begin) / duration)
            let eased = 1 - pow(1 - t, 3)
            value.wrappedValue = start + (target - start) * eased
            if t >= 1 { break }
            try? await Task.sleep(for: .milliseconds(8))
        }
    }
}
