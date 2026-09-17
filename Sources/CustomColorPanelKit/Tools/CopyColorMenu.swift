//
//  CopyColorMenu.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 16/09/2026.
//

import SwiftUI

struct CopyColorMenu: View {
    let color: HSBAColor
    var body: some View {
        Menu {
            Button{ NSPasteboard.copy(color.hexString) }
            label: {
                Text("HEX")
                Text("\(color.hexString)")
            }
            
            Button{ NSPasteboard.copy(color.hsvString) }
            label: {
                Text("HSV")
                Text("\(color.hsvString)")
            }
            
            Button { NSPasteboard.copy(color.hsl.string) }
            label: {
                Text("HSL")
                Text("\(color.hsl.string)")
            }
            
            Button{ NSPasteboard.copy(color.rgb.string) }
            label: {
                Text("RGB")
                Text("\(color.rgb.string)")
            }
            
            Button{ NSPasteboard.copy(color.cmyk.string) }
            label: {
                Text("CMYK")
                Text("\(color.cmyk.string)")
            }
            
        } label: {
            Label("Copy As", systemImage: "doc.on.doc")
        }
    }
}
