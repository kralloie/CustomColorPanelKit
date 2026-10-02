//
//  CopyToClipboard.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 17/07/2026.
//

import AppKit

extension NSPasteboard {
    /// Copies the passed string to the clipboard.
    ///
    /// - Parameter string: The string content that is copied to the clipboard.
    static func copy(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
