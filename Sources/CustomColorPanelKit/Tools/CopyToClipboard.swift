//
//  CopyToClipboard.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 17/07/2026.
//

import AppKit

extension NSPasteboard {
    static func copy(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
