//
//  SidebarView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 23/06/2026.
//

import SwiftUI

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

struct SidebarView: View {
    @Binding var color: HSBAColor
    @Binding var pickerMode: PickerMode
    
    var colorHistory: ColorHistory
    var alignment: Alignment
    var oppositeAlignment: Alignment {
        if alignment == .leading { .trailing } else { .leading }
    }
    
    @State private var isOpen: Bool = true
    @State private var panelWidth = SidebarLayout.panelWidth
    @State private var dragStartWidth: CGFloat? = nil
    
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

struct SidebarContent: View {
    @Binding var color: HSBAColor
    @Binding var pickerMode: PickerMode
    var colorHistory: ColorHistory
    var panelWidth: CGFloat
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

    private struct ColorDisclosureGroup<Content: View>: View {
        @State private var isOpen: Bool = false
        let title: String
        let value: String
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
        
        private struct ColorDisclosureGroupToggle: View {
            @Binding var isOpen: Bool
            @State private var hoveringButton: Bool = false
            
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

    private struct ToggleSidebarButton: View {
        let alignment: Alignment
        @Binding var isOpen: Bool
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
