//
//  ImmediatePanGestureRecognizer.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 31/08/2026.
//

import AppKit

/// A pan gesture recognizer that begins on mouse down instead of after the pointer moves.
///
/// This is the AppKit equivalent of SwiftUI's `DragGesture(minimumDistance: 0)`.
final class ImmediatePanGestureRecognizer: NSPanGestureRecognizer {
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        state = .began
    }
}
