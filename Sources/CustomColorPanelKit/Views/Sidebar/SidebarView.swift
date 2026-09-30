//
//  SidebarView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 23/06/2026.
//

import SwiftUI


/// Layout constants shared by every piece of ``SidebarView``.
enum SidebarLayout {
    static let panelInnerPadding: CGFloat = 10
    static let panelOuterPadding: CGFloat = 8
    static let sidebarCornerRadius: CGFloat = 12
    static let componentLabelWidth: CGFloat = 45
    static let colorComponentRowCornerRadius: CGFloat = 12
    static let colorComponentRowMinWidth: CGFloat = 210
    static let colorPreviewSize: CGFloat = 80
    static let componentRowPadding: CGFloat = 8
}

/// The background view for color component rows to contrast with the translucent background.
struct ColorComponentBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius)
            .fill(.background.secondary)
    }
}

/// The sidebar panel of the color picker, containing features for modifying and inspecting the color.
///
/// - The selector for changing the color picker mode between the three available modes.
/// - The preview of the current color with a checkerboard pattern background to contrast the opacity.
/// - A random color generator.
/// - An eye dropper for sampling colors from anywhere on the screen.
/// - A set of premade palettes to use as reference.
/// - A set of group rows for each color component and their respective channels.
/// - A color history grid with up to 144 previously selected colors.
struct SidebarView: View {
    /// The color currently being edited, shared with the rest of the picker.
    @Binding var color: HSBAColor
    /// The active picker mode (e.g. HSV Square, Hue Ring), shared with the rest of the picker.
    @Binding var pickerMode: PickerMode
    
    /// The object storing and managing previously selected colors through the picker session.
    var colorHistory: ColorHistory
    
    /// Stores the current color in the history.
    ///
    /// Passed to child views as a closure instead of forwarding the whole ``ColorHistory`` object.
    func storeColor() { colorHistory.add(color) }
    
    /// Creates the sidebar of the color picker.
    ///
    /// - Parameters:
    ///   - color: A binding to the color currently being edited.
    ///   - pickerMode: A binding to the active picker mode state.
    ///   - colorHistory: The instance of the ``ColorHistory`` object being used to manage color history.
    init(color: Binding<HSBAColor>, pickerMode: Binding<PickerMode>, colorHistory: ColorHistory) {
        _color = color
        _pickerMode = pickerMode
        self.colorHistory = colorHistory
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                PickerModeSelectorView(selectedMode: $pickerMode)
                
                HStack {
                    colorPreview
                    
                    EyeDropperButton(pickedColor: $color, storeColor: { colorHistory.add(color) })
                    
                    DiceButton(color: $color, storeColor: { colorHistory.add(color) })
                    
                    PaletteButton(color: $color, storeColor: { colorHistory.add(color) })
                }
                
                hexValue
                
                    
                VStack(spacing: 0) {
                    ColorDisclosureGroup(title: "HSV", value: color.hsvString, content: { hsvValues })
                        .background(alignment: .bottom) {
                            Divider()
                                .padding(.horizontal, 6)
                        }
                    
                    ColorDisclosureGroup(title: "HSL", value: color.hsl.string, content: { hslValues })
                        .background(alignment: .bottom) {
                            Divider()
                                .padding(.horizontal, 6)
                        }
                    
                    ColorDisclosureGroup(title: "RGB", value: color.rgb.string, content: { rgbValues })
                        .background(alignment: .bottom) {
                            Divider()
                                .padding(.horizontal, 6)
                        }
                    
                    ColorDisclosureGroup(title: "CMYK", value: color.cmyk.string, content: { cmykValues })
                }
                .background {
                    RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius)
                        .fill(.background.secondary)
                }
                .clipShape(RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius))
                
                alphaValue
                
                Spacer()
                
                ColorHistoryView(colorHistory: colorHistory)
            }
            .padding(SidebarLayout.panelInnerPadding)
        }
        .background {
            SidebarBackground(material: .sidebar, blendingMode: .behindWindow)
                   .ignoresSafeArea(.container, edges: .top)
        }
        .accessibilityLabel("Sidebar")
    }
}

extension SidebarView {
    /// The swatch representing the current color with a checkerboard pattern background and a context menu for copying the color.
    private var colorPreview: some View {
        let size: CGFloat = SidebarLayout.colorPreviewSize
        return ColorExample(color: color)
            .frame(width: size, height: size)
            .background(
                CheckerboardView(rows: 5)
                    .frame(width: size - 1, height: size - 1)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(radius: 2)
            .contextMenu { CopyColorMenu(color: color) }
            .padding(.bottom, 10)
            .accessibilityRepresentation {
                Rectangle()
                    .accessibilityLabel(Text("Current Color: \(Text(color.hexString).speechSpellsOutCharacters(true))"))
                    .contextMenu { CopyColorMenu(color: color) }
            }
    }
    
    /// The row for editing the color's hex string.
    private var hexValue: some View {
        HStack {
            Text("HEX")
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            
            Spacer()
            
            ColorComponentField(value: $color.hex, inputType: .hex, label: "Hex", storeColor: storeColor)
        }
        .frame(minWidth: SidebarLayout.colorComponentRowMinWidth)
        .padding(SidebarLayout.componentRowPadding)
        .background(ColorComponentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hex")
    }
    
    /// The row for editing the color's alpha channel.
    private var alphaValue: some View {
        HStack {
            Text("Alpha")
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            
            Spacer()
            
            ColorComponentField(value: $color.alpha, inputType: .percentage, label: "Alpha")
        }
        .frame(minWidth: SidebarLayout.colorComponentRowMinWidth)
        .padding(SidebarLayout.componentRowPadding)
        .background(ColorComponentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Alpha")
    }
    
    /// The fields shown when the HSV disclosure group is expanded.
    private var hsvValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "H") {
                ColorComponentField(value: $color.hue, inputType: .degrees, label: "Hue", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "S") {
                ColorComponentField(value: $color.saturation, inputType: .percentage, label: "Saturation", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "V") {
                ColorComponentField(value: $color.brightness, inputType: .percentage, label: "Brightness", storeColor: storeColor)
            }
        }
    }
    
    /// The fields shown when the HSL disclosure group is expanded.
    private var hslValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "H") {
                ColorComponentField(value: $color.hsl.hue, inputType: .degrees, label: "Hue", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "S") {
                ColorComponentField(value: $color.hsl.saturation, inputType: .percentage, label: "Saturation", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "L") {
                ColorComponentField(value: $color.hsl.lightness, inputType: .percentage, label: "Lightness", storeColor: storeColor)
            }
        }
    }
    
    /// The fields shown when the RGB disclosure group is expanded.
    private var rgbValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "R") {
                ColorComponentField(value: $color.rgb.red, inputType: .numerical, label: "Red", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "G") {
                ColorComponentField(value: $color.rgb.green, inputType: .numerical, label: "Green", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "B") {
                ColorComponentField(value: $color.rgb.blue, inputType: .numerical, label: "Blue", storeColor: storeColor)
            }
        }
    }
    
    /// The fields shown when the CMYK disclosure group is expanded.
    private var cmykValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "C") {
                ColorComponentField(value: $color.cmyk.cyan, inputType: .percentage, label: "Cyan", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "M") {
                ColorComponentField(value: $color.cmyk.magenta, inputType: .percentage, label: "Magenta", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "Y") {
                ColorComponentField(value: $color.cmyk.yellow, inputType: .percentage, label: "Yellow", storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "K") {
                ColorComponentField(value: $color.cmyk.key, inputType: .percentage, label: "Black", storeColor: storeColor)
            }
        }
    }

    /// A collapsible row that shows a component group's title and when closed, a compact summary of the current value of all components (e.g. "180°, 50%, 50%").
    ///
    /// Expanding the group reveals a row for each component and its editable fields.
    private struct ColorDisclosureGroup<Content: View>: View {
        /// Whether the group is currently expanded.
        @State private var isOpen: Bool = false
        /// The title of the group (e.g. "HSV").
        let title: String
        /// The value of the group to show when collapsed.
        let value: String
        /// The rows for each component shown while the group is expanded.
        @ViewBuilder let content: () -> Content
        
        var body: some View {
            VStack(spacing: 0) {
                Button {
                    toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("\(title)")
                            .lineLimit(1)
                            .fontWeight(.bold)
                            .padding(.leading, SidebarLayout.componentRowPadding)
                        
                        Spacer()
                        
                        Text(!isOpen ? value : "")
                            .animation(nil, value: isOpen)
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .rotationEffect(isOpen ? Angle(degrees: 90) : Angle(degrees: 0))
                    }
                }
                .buttonStyle(ColorComponentGroupButtonStyle())
                
                if isOpen {
                    content()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .padding(.top, 6)
                        .padding(.bottom, 18)
                }
            }
            .frame(minWidth: SidebarLayout.colorComponentRowMinWidth)
        }
        
        func toggle() { withAnimation(.easeInOut(duration: 0.1)) { isOpen.toggle() } }
    }
}

#Preview {
    SidebarView(color: .constant(HSBAColor(with: .orange)), pickerMode: .constant(.hsvSquare), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
