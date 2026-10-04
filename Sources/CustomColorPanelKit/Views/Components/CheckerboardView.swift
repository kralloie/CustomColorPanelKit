//
//  CheckerboardView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 08/06/2026.
//

import SwiftUI

/// A view that displays a white and gray checkerboard pattern.
///
/// Its purpose is to be used as background of the color preview and sliders to give a better contrast
/// when previewing opacity.
struct CheckerboardView: View {
    /// The number of tile rows used to size each square based on the view's shorter dimension.
    let rows: UInt8
    
    private let color1: Color = .white
    private let color2: Color = Color(white: 0.50)
    
    var body: some View {
        Canvas { ctx, size in
            let tileSize = min(size.height, size.width) / CGFloat(rows)
            let cols = Int(ceil(size.width / tileSize))
            let rows = Int(ceil(size.height / tileSize))
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    ctx.fill(
                        Path(CGRect(
                            x: CGFloat(col) * tileSize,
                            y: CGFloat(row) * tileSize,
                            width: tileSize,
                            height: tileSize
                        )),
                        with: .color(isLight ? color1 : color2)
                    )
                }
            }
        }
    }
}
