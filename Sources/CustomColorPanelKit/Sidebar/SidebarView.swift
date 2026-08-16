//
//  ColorValuesView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 23/06/2026.
//

import SwiftUI

private enum Layout {
    static let panelWidth: CGFloat = 230
    static let panelInnerPadding: CGFloat = 10
    static let panelOuterPadding: CGFloat = 8
    static let sidebarCornerRadius: CGFloat = 12
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
    @State private var panelWidth = Layout.panelWidth
    @State private var dragStartWidth: CGFloat? = nil
    
    init(alignment: HorizontalAlignment, color: Binding<HSBAColor>, pickerMode: Binding<PickerMode>, colorHistory: ColorHistory) {
        let alignment = alignment == .center ? .leading : alignment
        self.alignment = Alignment(horizontal: alignment, vertical: .center)
        _color = color
        _pickerMode = pickerMode
        self.colorHistory = colorHistory
    }
    
    private func storeColor() { colorHistory.add(color) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                PickerModeSelectorView(selectedMode: $pickerMode)
                
                colorPreview
                
                VStack(spacing: 15) {
                    hexValue
                    
                    alphaValue
                    
                    ColorDisclosureGroup(title: "HSV", value: color.hsvString, content: hsvValues)
                    
                    ColorDisclosureGroup(title: "HSL", value: color.hsl.string, content: hslValues)
                    
                    ColorDisclosureGroup(title: "RGB", value: color.rgb.string, content: rgbValues)
                    
                    ColorDisclosureGroup(title: "CMYK", value: color.cmyk.string, content: cmykValues)
                    
                    ColorHistoryView(colorHistory: colorHistory)
                }
                .padding(10)

            }
            .padding(Layout.panelInnerPadding)
            .frame(width: isOpen ? panelWidth : 0)
        }
        .frame(width: isOpen ? panelWidth : 0)
        .scrollIndicators(.hidden)
        .clipped()
        .background {
            RoundedRectangle(cornerRadius: Layout.sidebarCornerRadius)
                .fill(.background)
                .stroke(.separator, lineWidth: 1)
        }
        .overlay(alignment: oppositeAlignment) { dragHandle }
        .overlay(alignment: oppositeAlignment) {
            TogglePanelButton(alignment: alignment, isOpen: $isOpen, panelWidth: $panelWidth)
        }
        .padding(isOpen ? Layout.panelOuterPadding : 0)
    }
}

extension SidebarView {
    private var dragHandle: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 4)
            .contentShape(Rectangle())
            .onHover { hovering in
                guard dragStartWidth == nil else { return }
                if hovering { NSCursor.resizeLeftRight.set() } else { NSCursor.arrow.set() }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartWidth == nil { dragStartWidth = panelWidth }
                        let delta = alignment == .trailing
                        ? -(value.location.x - value.startLocation.x)
                        : (value.location.x - value.startLocation.x)
                        
                        let newWidth = (dragStartWidth ?? panelWidth) + delta
                        
                        panelWidth = min(500, max(newWidth, 0))
                        
                        if isOpen && panelWidth < 40 {
                            isOpen = false
                        } else if !isOpen && panelWidth > 60 {
                            isOpen = true
                        }
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                        NSCursor.pop()
                    }
            )
    }
    
    private var colorPreview: some View {
        ColorExample(color: color)
            .frame(width: min(panelWidth * 0.8, 80), height: min(panelWidth * 0.8, 80))
            .background(CheckerboardView())
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.separator, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .trailing) {
                EyeDropperView(pickedColor: $color, storeColor: { colorHistory.add($0) })
                    .offset(x: 30)
            }
            .padding(.bottom, 10)
    }
    
    private var hexValue: some View {
        HStack {
            Text("HEX:")
                .lineLimit(1)
                .bold()
            
            Spacer()
            
            ColorComponentField(value: $color.hex, inputType: .hex, storeColor: storeColor)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .clearGlassEffect(in: RoundedRectangle(cornerRadius: 24))
        }
    }
    
    private var alphaValue: some View {
        HStack {
            Text("Alpha:")
                .lineLimit(1)
                .bold()
            
            Spacer()
            
            ColorComponentField(value: $color.alpha, inputType: .percentage)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .clearGlassEffect(in: RoundedRectangle(cornerRadius: 24))
        }
    }
    
    private var hsvValues: some View {
        section {
            ColorComponentFieldContainer(component: "H") {
                ColorComponentField(value: $color.hue, inputType: .degrees, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "S") {
                ColorComponentField(value: $color.saturation, inputType: .percentage, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "V") {
                ColorComponentField(value: $color.brightness, inputType: .percentage, storeColor: storeColor)
            }
        }
    }
    
    private var hslValues: some View {
        section {
            ColorComponentFieldContainer(component: "H") {
                ColorComponentField(value: $color.hsl.hue, inputType: .degrees, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "S") {
                ColorComponentField(value: $color.hsl.saturation, inputType: .percentage, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "L") {
                ColorComponentField(value: $color.hsl.lightness, inputType: .percentage, storeColor: storeColor)
            }
        }
    }
    
    private var rgbValues: some View {
        section {
            ColorComponentFieldContainer(component: "R") {
                ColorComponentField(value: $color.rgb.red, inputType: .numerical, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "G") {
                ColorComponentField(value: $color.rgb.green, inputType: .numerical, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "B") {
                ColorComponentField(value: $color.rgb.blue, inputType: .numerical, storeColor: storeColor)
            }
        }
    }
    
    private var cmykValues: some View {
        section {
            ColorComponentFieldContainer(component: "C") {
                ColorComponentField(value: $color.cmyk.cyan, inputType: .percentage, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "M") {
                ColorComponentField(value: $color.cmyk.magenta, inputType: .percentage, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "Y") {
                ColorComponentField(value: $color.cmyk.yellow, inputType: .percentage, storeColor: storeColor)
            }
            ColorComponentFieldContainer(component: "K") {
                ColorComponentField(value: $color.cmyk.key, inputType: .percentage, storeColor: storeColor)
            }
        }
    }
    
    private func section<Content: View> (@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) {
            content()
                .padding(.horizontal, 4)
        }
    }

    private struct TogglePanelButton: View {
        let alignment: Alignment
        @Binding var isOpen: Bool
        @Binding var panelWidth: CGFloat
        @State private var isHoveringTogglePanel: Bool = false
        var chevron: String {
            if alignment == .trailing {
                isOpen ? "chevron.left" : "chevron.right"
            } else {
                isOpen ? "chevron.right" : "chevron.left"
            }
        }
        var offset: CGFloat { isOpen ? 10 : 25 }
        
        var body: some View {
            Image(systemName: chevron)
                .frame(width: 20, height: 20)
                .background {
                    Circle()
                        .fill(.thickMaterial)
                        .stroke(.gray.opacity(0.2), lineWidth: 1)
                }
                .overlay {
                    Circle()
                        .fill(isHoveringTogglePanel ? .gray.opacity(0.2) : .clear)
                }
                .offset(x: alignment == .trailing ? -offset : offset)
                .onTapGesture {
                    if !isOpen { panelWidth = 200 }
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isOpen.toggle()
                    }
                }
                .onHover { isHoveringTogglePanel = $0 }
                .animation(.easeInOut(duration: 0.1), value: isHoveringTogglePanel)
        }
    }
    
    private struct ColorDisclosureGroup<Content: View>: View {
        @State private var isOpen: Bool = false
        let title: String
        let value: String
        var content: Content
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chevron.right")
                        .rotationEffect(isOpen ? Angle(degrees: 90) : Angle(degrees: 0))
                        .frame(width: 15, height: 10)
                        .bold()
                    Text("\(title)")
                        .lineLimit(1)
                        .fontWeight(.bold)
                    Spacer()
                    Text(!isOpen ? value : "")
                        .animation(nil, value: isOpen)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.1)) { isOpen.toggle() }
                }
                
                content
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxHeight: isOpen ? .infinity : 0, alignment: .top)
                    .padding(.vertical, isOpen ? 4 : 0)
                    .opacity(isOpen ? 1 : 0)
                    .clipped()
                    .allowsHitTesting(isOpen)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .clearGlassEffect(in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

#Preview {
    SidebarView(alignment: .trailing, color: .constant(HSBAColor(with: .orange)), pickerMode: .constant(.hsvSquare), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
