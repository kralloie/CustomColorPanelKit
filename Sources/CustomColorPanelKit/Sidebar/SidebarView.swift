//
//  ColorValuesView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 23/06/2026.
//

import SwiftUI

enum SidebarLayout {
    static let panelWidth: CGFloat = 270
    static let panelInnerPadding: CGFloat = 10
    static let panelOuterPadding: CGFloat = 8
    static let sidebarCornerRadius: CGFloat = 12
    static let componentLabelWidth: CGFloat = 40
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
    private var sliderWidth: CGFloat { max(panelWidth - 190, 10) }
    
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
                    
                    ColorDisclosureGroup(title: "HSV", value: color.hsvString, content: hsvValues)
                    
                    ColorDisclosureGroup(title: "HSL", value: color.hsl.string, content: hslValues)
                    
                    ColorDisclosureGroup(title: "RGB", value: color.rgb.string, content: rgbValues)
                    
                    ColorDisclosureGroup(title: "CMYK", value: color.cmyk.string, content: cmykValues)
                    
                    alphaValue
                    
                    ColorHistoryView(colorHistory: colorHistory)
                }
                .padding(10)

            }
            .padding(SidebarLayout.panelInnerPadding)
            .frame(width: isOpen ? panelWidth : 0)
        }
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
            TogglePanelButton(alignment: alignment, isOpen: $isOpen, panelWidth: $panelWidth)
        }
        .padding(isOpen ? SidebarLayout.panelOuterPadding : 0)
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
            Text("HEX")
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            
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
            Text("Alpha")
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            
            ColorComponentField(value: $color.alpha, inputType: .percentage, sliderWidth: sliderWidth)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .clearGlassEffect(in: RoundedRectangle(cornerRadius: 24))
        }
    }
    
    private var hsvValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "H") {
                ColorComponentField(value: $color.hue, inputType: .degrees, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "S") {
                ColorComponentField(value: $color.saturation, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "V") {
                ColorComponentField(value: $color.brightness, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
        }
    }
    
    private var hslValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "H") {
                ColorComponentField(value: $color.hsl.hue, inputType: .degrees, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "S") {
                ColorComponentField(value: $color.hsl.saturation, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "L") {
                ColorComponentField(value: $color.hsl.lightness, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
        }
    }
    
    private var rgbValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "R") {
                ColorComponentField(value: $color.rgb.red, inputType: .numerical, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "G") {
                ColorComponentField(value: $color.rgb.green, inputType: .numerical, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "B") {
                ColorComponentField(value: $color.rgb.blue, inputType: .numerical, storeColor: storeColor, sliderWidth: sliderWidth)
            }
        }
    }
    
    private var cmykValues: some View {
        VStack(spacing: 10) {
            ColorComponentFieldContainer(component: "C") {
                ColorComponentField(value: $color.cmyk.cyan, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "M") {
                ColorComponentField(value: $color.cmyk.magenta, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "Y") {
                ColorComponentField(value: $color.cmyk.yellow, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
            ColorComponentFieldContainer(component: "K") {
                ColorComponentField(value: $color.cmyk.key, inputType: .percentage, storeColor: storeColor, sliderWidth: sliderWidth)
            }
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
                        .glassEffect(.clear.tint(isHoveringTogglePanel ? .gray : .clear), in: Circle())
                        .animation(.easeInOut(duration: 0.1), value: isHoveringTogglePanel)
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
        @State private var hoveringButton: Bool = false
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
                        .padding(5)
                        .contentShape(Circle())
                        .background {
                            Circle()
                                .glassEffect(.clear.tint(hoveringButton ? .gray : .clear), in: Circle())
                                .animation(.easeInOut(duration: 0.1), value: hoveringButton)
                        }
                        .onHover { hoveringButton = $0 }
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.1)) { isOpen.toggle() } }
                    
                    Text("\(title)")
                        .lineLimit(1)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(!isOpen ? value : "")
                        .animation(nil, value: isOpen)
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                
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
                RoundedRectangle(cornerRadius: 24)
                    .clearGlassEffect(in: RoundedRectangle(cornerRadius: 24))
            }
        }
    }
}

#Preview {
    SidebarView(alignment: .trailing, color: .constant(HSBAColor(with: .orange)), pickerMode: .constant(.hsvSquare), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
