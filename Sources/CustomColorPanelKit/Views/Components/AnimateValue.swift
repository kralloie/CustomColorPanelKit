//
//  AnimateValue.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 01/10/2026.
//

import SwiftUI

/// Animates a value from its current number to a target with an ease-out curve.
///
/// Returns immediately. The animation runs in a task on the main actor that writes
/// intermediate values to `value` about every 8 ms. Starting a new animation cancels
/// the one stored in `valueAnimation`.
///
/// - Parameters:
///   - reduceMotion: Whether the reduce motion setting is enabled.
///   - value: The binding to animate. Its current value is the starting point.
///   - target: The value to animate toward.
///   - duration: How long the animation takes.
///   - valueAnimation: A binding that holds the running task, so callers can cancel or await it.
///     Any task already stored there is cancelled first.
func animateValue(
    reduceMotion: Bool,
    _ value: Binding<CGFloat>,
    to target: CGFloat,
    duration: Duration = .milliseconds(125),
    valueAnimation: Binding<Task<Void, Never>?>
) {
    valueAnimation.wrappedValue?.cancel()
    if reduceMotion {
        value.wrappedValue = target
        return
    }
    
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
