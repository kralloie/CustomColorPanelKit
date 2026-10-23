//
//  ColorPanelView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 25/06/2026.
//

import SwiftUI

/// The representation of a picker mode.
public enum PickerMode: Int, CaseIterable, Hashable {
    /// The available picker modes.
    case hueRing, hsvSquare, hueSphere
    
    /// The title for the picker mode.
    var title: LocalizedStringResource {
        switch self {
        case .hueRing: return .pickerHueRing
        case .hsvSquare: return .pickerHsvSquare
        case .hueSphere: return .pickerHueSphere
        }
    }
}

/// A color panel for macOS with Metal-rendered pickers and a sidebar of precise color controls.
///
/// Bind it to a SwiftUI `Color`, and the panel edits that color as someone uses it.
///
/// Passing the optional `initialMode` parameter to `ColorPanelView` can set the starting `PickerMode` to any of the three available modes, by default it is set `.hueRing`.
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
    @Environment(\.self) private var environment
    /// A binding to the color being edited.
    @Binding private var selection: Color
    /// The selected picker mode.
    @State var pickerMode: PickerMode
    /// The main instance of the color history.
    @State var colorHistory = ColorHistory()
    /// The router that stores the event called when the user scrolls on scrollable controls.
    @State private var scrollWheelRouter = ScrollWheelRouter()
    
    
    /// Creates a color picker panel bound to a SwiftUI color.
    ///
    /// - Parameters:
    ///   - selection: A binding to the color displayed and modified by the panel.
    ///   - initialMode: The starting picker mode of the color panel, `.hueRing` by default.
    public init(_ selection: Binding<Color>, initialMode: PickerMode = .hueRing) {
        _selection = selection
        self._pickerMode = State(initialValue: initialMode)
    }
    
    public var body: some View {
        PanelContent(
            selection: $selection,
            pickerMode: $pickerMode,
            environmentValues: environment,
            colorHistory: colorHistory,
            scrollWheelRouter: scrollWheelRouter
        )
    }
    
    @MainActor
    private final class SelectionSync {
        var publishedSelection: Color?
    }
    
    struct PanelContent: View {
        @Environment(\.self) var environment
        /// The color that will be edited in the picker.
        @State private var color: HSBAColor
        /// The selected picker mode.
        @Binding var pickerMode: PickerMode
        /// A binding to the color being edited.
        @Binding var selection: Color
        /// The object that handles the synchronization between the color used in the picker and the color passed by the user.
        @State private var selectionSync = SelectionSync()
        /// The main instance of the color history.
        let colorHistory: ColorHistory
        /// The router that stores the event called when the user scrolls on scrollable controls.
        let scrollWheelRouter: ScrollWheelRouter
        
        init(selection: Binding<Color>, pickerMode: Binding<PickerMode>, environmentValues: EnvironmentValues, colorHistory: ColorHistory, scrollWheelRouter: ScrollWheelRouter) {
            _selection = selection
            _pickerMode = pickerMode
            _color = State(
                initialValue: HSBAColor(with: selection.wrappedValue, in: environmentValues)
            )
            self.colorHistory = colorHistory
            self.scrollWheelRouter = scrollWheelRouter
        }

        var body: some View {
            NavigationSplitView {
                SidebarView(color: $color, pickerMode: $pickerMode, colorHistory: colorHistory)
            } detail : {
                switch pickerMode {
                case .hueRing:
                    HueRingPickerView(color: $color, colorHistory: colorHistory)
                case .hsvSquare:
                    HSVSquarePickerView(color: $color, colorHistory: colorHistory)
                case .hueSphere:
                    HueSpherePickerView(color: $color, colorHistory: colorHistory)
                }

            }
            .environment(scrollWheelRouter)
            .background {
                ScrollWheelMonitor(router: scrollWheelRouter, color: { color }, storeColor: { colorHistory.add($0) })
                    .equatable()
            }
            .onChange(of: color) {
                let newSelection = color.color
                
                guard selection != newSelection else { return }
                
                selectionSync.publishedSelection = newSelection
                selection = newSelection
            }
            .onChange(of: selection) {
                if selection == selectionSync.publishedSelection {
                    selectionSync.publishedSelection = nil
                    return
                }
                
                selectionSync.publishedSelection = nil
                color = HSBAColor(with: selection, in: environment)
            }
        }
    }
}
