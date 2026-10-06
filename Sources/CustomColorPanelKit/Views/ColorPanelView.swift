//
//  ColorPanelView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

/// The representation of a picker mode.
enum PickerMode: Int, CaseIterable, Hashable {
    /// The available picker modes.
    case hueRing, hsvSquare, hsvSphere
    
    /// The title for the picker mode.
    var string: String {
        switch self {
            case .hueRing: return "Hue Ring"
            case .hsvSquare: return "HSV Square"
            case .hsvSphere: return "HSV Sphere"
        }
    }
}

/// A color panel for macOS with Metal-rendered pickers and a sidebar of precise color controls.
///
/// Bind it to a SwiftUI `Color`, and the panel edits that color as someone uses it.
///
/// ```swift
/// struct ContentView: View {
///     @State private var color = Color.red
///
///     var body: some View {
///         ColorPanelView($color)
///     }
/// }
/// ```
///
/// ## Pickers
///
/// A segmented control at the top of the sidebar switches between three pickers.
/// Each has an opacity slider below it.
///
/// - **Hue ring:** a ring that sets the hue, with a triangle inside it for saturation and brightness.
/// - **HSV square:** a square for saturation and brightness, with a vertical hue slider.
/// - **Hue sphere:** a sphere where the angle sets the hue and the distance from the center sets the saturation, with a vertical brightness slider.
///
/// ## Sidebar
///
/// - A preview of the current color over a checkerboard, so opacity is visible, with a context menu for copying the color.
/// - An eyedropper that samples a color from anywhere on the screen, a random color button, and a set of premade palettes.
/// - An editable hex field, and collapsible HSV, HSL, RGB and CMYK groups. Each channel has a slider, a text field and a stepper.
/// - An alpha field.
/// - A history of up to 144 recently used colors.
///
/// Sliders and fields also respond to the scroll wheel, and the arrow keys step the value of a focused field.
///
/// - Note: Requires macOS 26 or later.
public struct ColorPanelView: View {
    /// A binding to the color being edited.
    @Binding var selection: Color
    /// The color that will be edited in the picker.
    @State var color: HSBAColor
    ///
    @State private var publishedSelection: Color?
    /// The main instance of the color history.
    @State var colorHistory = ColorHistory()
    /// The selected picker mode, by default is ``.hueRing``.
    @State var pickerMode: PickerMode = .hueRing
        
    /// Creates a ``ColorPanelView``.
    ///
    /// - Parameter color: The color that this color picker will be editing.
    public init(_ color: Binding<Color>) {
        self._selection = color
        self.color = HSBAColor(with: color.wrappedValue)
    }
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
        } detail : {
            switch pickerMode {
            case .hueRing:
                HueRingPickerView(color: $color, colorHistory: colorHistory)
            case .hsvSquare:
                HSVSquarePickerView(color: $color, colorHistory: colorHistory)
            case .hsvSphere:
                HueSpherePickerView(color: $color, colorHistory: colorHistory)
            }

        }
        .background {
            ScrollWheelMonitor(router: ScrollWheelRouter.shared, color: $color, storeColor: { colorHistory.add($0) })
        }
        .onChange(of: colorHistory.pendingChange) {
            guard var newColor = colorHistory.pendingChange else { return }
            newColor.alpha = color.alpha
            color = newColor
            colorHistory.pendingChange = nil
        }
        .onChange(of: color) {
            let newSelection = color.color
            
            guard selection != newSelection else { return }
            
            publishedSelection = newSelection
            selection = newSelection
        }
        .onChange(of: selection) {
            if selection == publishedSelection {
                publishedSelection = nil
                return
            }
            
            publishedSelection = nil
            color = HSBAColor(with: selection)
        }
    }
}
