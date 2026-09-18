//
//  DiceButton.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 14/09/2026.
//

import SwiftUI

struct DiceButton: View {
    @Binding var color: HSBAColor
    let storeColor: () -> Void
    
    var body: some View {
        Button {
            color.rgb = .init(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1))
            storeColor()
        } label: {
            Image(systemName: "dice")
        }
        .buttonStyle(.circleGlass)
    }
}
