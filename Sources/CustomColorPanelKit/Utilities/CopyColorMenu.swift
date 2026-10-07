//
//  CopyColorMenu.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 16/09/2026.
//

import SwiftUI

/// A menu for copying an ``HSBAColor`` in the available string formats.
struct CopyColorMenu: View {
    /// The color to be copied.
    let color: HSBAColor
    
    var body: some View {
        Menu {
            Button{ NSPasteboard.copy(color.hexString) }
            label: {
                Text(verbatim: "HEX")
                Text(verbatim: color.hexString)
            }
            
            Button{ NSPasteboard.copy(color.hsvString) }
            label: {
                Text(verbatim: "HSV")
                Text(verbatim: color.hsvString)
            }
            
            Button { NSPasteboard.copy(color.hsl.string) }
            label: {
                Text(verbatim: "HSL")
                Text(verbatim: color.hsl.string)
            }
            
            Button{ NSPasteboard.copy(color.rgb.string) }
            label: {
                Text(verbatim: "RGB")
                Text(verbatim: color.rgb.string)
            }
            
            Button{ NSPasteboard.copy(color.cmyk.string) }
            label: {
                Text(verbatim: "CMYK")
                Text(verbatim: color.cmyk.string)
            }
            
        } label: {
            Label(.copyTitle, systemImage: "doc.on.doc")
        }
    }
}
