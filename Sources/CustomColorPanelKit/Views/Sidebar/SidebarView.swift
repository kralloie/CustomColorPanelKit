//
//  SidebarView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 23/06/2026.
//

import SwiftUI


/// Layout constants shared by every piece of ``SidebarView``
enum SidebarLayout {
    static let panelInnerPadding: CGFloat = 10
    static let panelOuterPadding: CGFloat = 8
    static let sidebarCornerRadius: CGFloat = 12
    static let componentLabelWidth: CGFloat = 45
    static let colorComponentRowCornerRadius: CGFloat = 24
    static let colorComponentRowMinWidth: CGFloat = 210
    static let dragHandleWidth: CGFloat = 4
    static let closeThresholdRatio: CGFloat = 0.5
    static let openThresholdRatio: CGFloat = 1.5
    static let maxPanelWidth: CGFloat = 500
    static var panelWidth: CGFloat {
        Self.colorComponentRowMinWidth + Self.panelInnerPadding * 2 + 20
    }
}

/// A resizable, collapsible sidebar that hosts the features for modifying and inspecting the color being edited.
///
/// ``SidebarView`` can be resized and closed using its inner edge drag handle or closed and opened using the floating toggle button.
struct SidebarView: View {
    /// The color currently being edited, shared with the rest of the picker.
    @Binding var color: HSBAColor
    /// The active picker mode (e.g. HSV Square, Hue Ring), shared with the rest of the picker.
    @Binding var pickerMode: PickerMode
    
    /// The object storing and managing previously selected colors through the picker session.
    var colorHistory: ColorHistory
    /// The edge of the parent view this sidebar is pinned to.
    var alignment: Alignment
    /// The opposite alignment where the drag handle and toggle button are anchored so they sit on the sidebar's inner edge.
    var oppositeAlignment: Alignment {
        if alignment == .leading { .trailing } else { .leading }
    }
    
    /// Whether the sidebar is currently expanded.
    @State private var isOpen: Bool = true
    /// The sidebar's current width while open.
    @State private var panelWidth = SidebarLayout.panelWidth
    /// The width stored when a drag gesture begins, used to compute the delta for the remainder of the gesture.`nil` when idle.
    @State private var dragStartWidth: CGFloat? = nil
    
    
    /// Creates a sidebar pinned to the specified horizontal edge of its parent view.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal edge to pin the sidebar to. A value of `.center` is treated as `.leading`.
    ///   - color: A binding to the color currently being edited.
    ///   - pickerMode: A binding to the active picker mode state.
    ///   - colorHistory: The instance of the ``ColorHistory`` object being used to manage color history.
    init(alignment: HorizontalAlignment, color: Binding<HSBAColor>, pickerMode: Binding<PickerMode>, colorHistory: ColorHistory) {
        let alignment = alignment == .center ? .leading : alignment
        self.alignment = Alignment(horizontal: alignment, vertical: .center)
        _color = color
        _pickerMode = pickerMode
        self.colorHistory = colorHistory
    }
    
    var body: some View {
        ScrollView {
            SidebarContent(color: $color, pickerMode: $pickerMode, colorHistory: colorHistory, panelWidth: panelWidth)
        }
        .accessibilityHidden(!isOpen)
        .accessibilityLabel("Sidebar")
        .frame(width: isOpen ? panelWidth : 0)
        .scrollIndicators(.hidden)
        .clipped()
        .background {
            RoundedRectangle(cornerRadius: SidebarLayout.sidebarCornerRadius)
                .fill(.background)
                .stroke(.separator, lineWidth: 1)
        }
        .overlay(alignment: oppositeAlignment) { dragHandle }
        .overlay(alignment: oppositeAlignment) {
            ToggleSidebarButton(alignment: alignment, isOpen: $isOpen, panelWidth: $panelWidth)
        }
        .padding(isOpen ? SidebarLayout.panelOuterPadding : 0)
    }
}


/// The scrollable content of ``SidebarView``: picker mode selector, color preview, per-component inspectors,
/// random color generator, eye dropper, palettes and history.
struct SidebarContent: View {
    /// The color currently being edited.
    @Binding var color: HSBAColor
    /// The active picker mode.
    @Binding var pickerMode: PickerMode
    
    /// The object storing and managing previously selected colors through the picker session.
    var colorHistory: ColorHistory
    /// The width available for layout, forwarded from parent ``SidebarView``.
    var panelWidth: CGFloat
    
    /// Stores the current ``color`` in ``colorHistory``.
    ///
    /// Passed to each ``ColorComponentField`` as a commit callback.
    private func storeColor() { colorHistory.add(color) }
    
    var body: some View {
        VStack(spacing: 4) {
            PickerModeSelectorView(selectedMode: $pickerMode)
            
            HStack {
                colorPreview
                
                EyeDropperButton(pickedColor: $color, storeColor: { colorHistory.add(color) })
                
                DiceButton(color: $color, storeColor: { colorHistory.add(color) })
                
                PaletteButton(color: $color, storeColor: { colorHistory.add(color) })
            }
            
            VStack(spacing: 15) {
                Divider()
                
                hexValue
                
                ColorDisclosureGroup(title: "HSV", value: color.hsvString, content: { hsvValues })
                
                ColorDisclosureGroup(title: "HSL", value: color.hsl.string, content: { hslValues })
                
                ColorDisclosureGroup(title: "RGB", value: color.rgb.string, content: { rgbValues })
                
                ColorDisclosureGroup(title: "CMYK", value: color.cmyk.string, content: { cmykValues })
                
                alphaValue
                
                Divider()
                
                ColorHistoryView(colorHistory: colorHistory)
            }
        }
        .padding(SidebarLayout.panelInnerPadding)
    }
}

extension SidebarContent {
    /// The swatch representing the current color with a checkerboard pattern background and a context menu for copying the color.
    private var colorPreview: some View {
        let size = min(panelWidth * 0.8, 80)
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
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius)
                .fill(.background.secondary)
        }
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
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius)
                .fill(.background.secondary)
        }
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
                HStack {
                    ColorDisclosureGroupToggle(isOpen: $isOpen)
                    
                    Text("\(title)")
                        .lineLimit(1)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(!isOpen ? value : "")
                        .animation(nil, value: isOpen)
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                
                if isOpen {
                    content()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                }
            }
            .frame(minWidth: SidebarLayout.colorComponentRowMinWidth)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: SidebarLayout.colorComponentRowCornerRadius)
                    .fill(.background.secondary)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(title) Components")
        }
        
        /// The button for toggling the parent disclosure group's expanded state.
        private struct ColorDisclosureGroupToggle: View {
            /// Whether the parent disclosure group is expanded.
            @Binding var isOpen: Bool
            
            var body: some View {
                Button {
                    withAnimation(.easeInOut(duration: 0.1)) { isOpen.toggle() }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(isOpen ? Angle(degrees: 90) : Angle(degrees: 0))
                        .bold()
                }
                .buttonStyle(.circleGlass)
                .accessibilityLabel(isOpen ? "Close Disclosure Group" : "Open Disclosure Group")
            }
        }
    }
}

extension SidebarView {
    
    /// An invisible strip on the sidebar's inner edge that resizes the sidebar via drag.
    ///
    /// - Note: Collapsing and reopening use different thresholds
    /// (``SidebarLayout/closeThresholdRatio`` vs. ``SidebarLayout/openThresholdRatio``)
    /// so the sidebar doesn't flicker open and closed right at one boundary.
    private var dragHandle: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: SidebarLayout.dragHandleWidth)
            .contentShape(Rectangle())
            .onHover { hovering in
                guard dragStartWidth == nil else { return }
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartWidth == nil { dragStartWidth = panelWidth }
                        let delta = alignment == .trailing
                        ? -(value.location.x - value.startLocation.x)
                        : (value.location.x - value.startLocation.x)
                        
                        let newWidth = (dragStartWidth ?? panelWidth) + delta
                        
                        if isOpen && newWidth < SidebarLayout.panelWidth * SidebarLayout.closeThresholdRatio {
                            isOpen = false
                            panelWidth = SidebarLayout.panelWidth
                        } else if !isOpen && newWidth > SidebarLayout.panelWidth * SidebarLayout.openThresholdRatio {
                            isOpen = true
                        }
                        
                        if isOpen {
                            panelWidth = min(SidebarLayout.maxPanelWidth, max(newWidth, SidebarLayout.panelWidth))
                        }
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                        NSCursor.pop()
                    }
            )
    }

    /// The button for toggling the sidebar's expanded state.
    private struct ToggleSidebarButton: View {
        /// The sidebar alignment to determine the horizontal offset of the button.
        let alignment: Alignment
        /// Whether the sidebar is currently expanded.
        @Binding var isOpen: Bool
        /// The current width of the sidebar.
        @Binding var panelWidth: CGFloat
        
        var offset: CGFloat { isOpen ? 10 : 25 }
        
        var body: some View {
            Button {
                if !isOpen { panelWidth = SidebarLayout.panelWidth }
                withAnimation(.easeInOut(duration: 0.1)) {
                    isOpen.toggle()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .rotationEffect(isOpen ? Angle(degrees: 0) : Angle(degrees: 180))
                    .bold()
            }
            .buttonStyle(.circleGlass)
            .offset(x: alignment == .trailing ? -offset : offset)
            .accessibilityLabel(isOpen ? "Hide Sidebar" : "Show Sidebar")
        }
    }
    
}

#Preview {
    SidebarView(alignment: .trailing, color: .constant(HSBAColor(with: .orange)), pickerMode: .constant(.hsvSquare), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
