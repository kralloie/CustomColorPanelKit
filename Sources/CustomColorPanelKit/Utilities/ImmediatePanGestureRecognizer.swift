//
//  ImmediatePanGestureRecognizer.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 31/08/2026.
//

import AppKit

final class ImmediatePanGestureRecognizer: NSPanGestureRecognizer {
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        state = .began
    }
}
