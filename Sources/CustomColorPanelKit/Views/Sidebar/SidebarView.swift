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
                
                VStack {
                    colorPreview
                    
                    HStack {
                        EyeDropperButton(setColor: { color = $0 }, storeColor: { colorHistory.add(color) })
                            .equatable()
                        
                        DiceButton(setColor: { color = $0 }, storeColor: { colorHistory.add(color) })
                            .equatable()
                        
                        PaletteButton(setColor: { color = $0 }, storeColor: { colorHistory.add(color) })
                            .equatable()
                    }
                }
                .padding(.bottom, 10)
                
                hexValue
            
                VStack(spacing: 0) {
                    ColorDisclosureGroup(title: "HSV", value: { color.hsvString }, content: { hsvValues })
                        .background(alignment: .bottom) {
                            Divider()
                                .padding(.horizontal, 6)
                        }
                    
                    ColorDisclosureGroup(title: "HSL", value: { color.hsl.string }, content: { hslValues })
                        .background(alignment: .bottom) {
                            Divider()
                                .padding(.horizontal, 6)
                        }
                    
                    ColorDisclosureGroup(title: "RGB", value: { color.rgb.string }, content: { rgbValues })
                        .background(alignment: .bottom) {
                            Divider()
                                .padding(.horizontal, 6)
                        }
                    
                    ColorDisclosureGroup(title: "CMYK", value: { color.cmyk.string }, content: { cmykValues })
                }
                .background {
                    RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius)
                        .fill(.background.secondary)
                }
                .clipShape(RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius))
                
                alphaValue
                
                Spacer()
                
                ColorHistoryView(colorHistory: colorHistory, setColor: { color = $0 })
                    .equatable()
            }
            .padding(SidebarLayout.panelInnerPadding)
        }
        .background {
            SidebarBackground()
                   .ignoresSafeArea(.container, edges: .top)
        }
        .accessibilityLabel(.sidebarAccessibilityLabel)
    }
}

extension SidebarView {
    /// The swatch representing the current color with a checkerboard pattern background and a context menu for copying the color.
    private var colorPreview: some View {
        let alphaValue = Double(color.alpha).formatted(.percent.precision(.fractionLength(0)))
        let size: CGFloat = SidebarLayout.colorPreviewSize
        return ColorExample(color: color)
            .frame(width: size, height: size)
            .background(
                CheckerboardView(rows: 5)
                    .clipShape(RoundedRectangle(cornerRadius: 6).inset(by: 0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(radius: 2)
            .contextMenu { CopyColorMenu(color: color) }
            .dropDestination(for: Color.self) { colors, _ in
                guard let droppedColor = colors.first else {
                    return false
                }
                color = HSBAColor(with: droppedColor)
                return true
            }
            .onDrag {
                color.dragItemProvider
            } preview: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.color)
                    .frame(width: 28, height: 28)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.separator)
                    }
            }
            .padding(.bottom, 10)
            .accessibilityRepresentation {
                Rectangle()
                    .accessibilityLabel { _ in
                        Text(.colorCurrent)
                        Text(verbatim: color.hexString)
                            .speechSpellsOutCharacters(true)
                        Text(.accessibilityOpacityValue(alphaValue))
                    }
                    .contextMenu { CopyColorMenu(color: color) }
            }
    }
    
    /// The row for editing the color's hex string.
    private var hexValue: some View {
        HStack {
            Text(.componentHex)
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            
            Spacer()
            
            componentField(.hex)
        }
        .frame(minWidth: SidebarLayout.colorComponentRowMinWidth)
        .padding(SidebarLayout.componentRowPadding)
        .background(ColorComponentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(.componentHex)
    }
    
    /// The row for editing the color's alpha channel.
    private var alphaValue: some View {
        HStack {
            Text(.componentAlpha)
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            
            Spacer()
            
            componentField(.alpha)
        }
        .frame(minWidth: SidebarLayout.colorComponentRowMinWidth)
        .padding(SidebarLayout.componentRowPadding)
        .background(ColorComponentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(.componentAlpha)
    }
    
    /// The fields shown when the HSV disclosure group is expanded.
    private var hsvValues: some View {
        VStack(spacing: 10) {
            componentField(.hsvHue)
            componentField(.hsvSaturation)
            componentField(.brightness)
        }
    }
    
    /// The fields shown when the HSL disclosure group is expanded.
    private var hslValues: some View {
        VStack(spacing: 10) {
            componentField(.hslHue)
            componentField(.hslSaturation)
            componentField(.lightness)
        }
    }
    
    /// The fields shown when the RGB disclosure group is expanded.
    private var rgbValues: some View {
        VStack(spacing: 10) {
            componentField(.red)
            componentField(.green)
            componentField(.blue)
        }
    }
    
    /// The fields shown when the CMYK disclosure group is expanded.
    private var cmykValues: some View {
        VStack(spacing: 10) {
            componentField(.cyan)
            componentField(.magenta)
            componentField(.yellow)
            componentField(.black)
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
        let value: () -> String
        /// The rows for each component shown while the group is expanded.
        let content: () -> Content
        
        init(title: String, value: @escaping () -> String, @ViewBuilder content: @escaping () -> Content) {
            self.title = title
            self.value = value
            self.content = content
        }
        
        var body: some View {
            VStack(spacing: 0) {
                Button {
                    toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text(verbatim: title)
                            .lineLimit(1)
                            .fontWeight(.bold)
                            .padding(.leading, SidebarLayout.componentRowPadding)
                        
                        Spacer()
                        
                        if !isOpen {
                            Text(value())
                                .animation(nil, value: isOpen)
                        }
                        
                        Image(systemName: "chevron.forward")
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
    
    /// Creates a field using the component's current value from the selected color.
    ///
    /// - Parameter component: The component to display and edit.
    @ViewBuilder
    private func componentField<Value: ColorComponentNumeric>(_ component: ColorComponent<Value>) -> some View {
        let keyPath = component.keyPath
        let value = color[keyPath: keyPath]

        let field = ColorComponentField(
            value: value,
            getValue: {
                color[keyPath: keyPath]
            },
            setValue: {
                color[keyPath: keyPath] = $0
            },
            inputType: component.inputType,
            label: component.label,
            storeColor: storeColor
        )
        .equatable()

        if let symbol = component.symbol {
            ColorComponentFieldContainer(component: symbol) {
                field
            }
        } else {
            field
        }
    }
}

#Preview {
    SidebarView(color: .constant(HSBAColor(with: .controlAccentColor)), pickerMode: .constant(.hsvSquare), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
