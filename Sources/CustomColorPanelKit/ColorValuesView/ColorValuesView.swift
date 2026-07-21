//
//  ColorValuesView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 23/06/2026.
//

import SwiftUI

private enum Layout {
    static let panelWidth: CGFloat = 200
    static let panelInnerPadding: CGFloat = 20
    static let panelOuterPadding: CGFloat = 8
}

struct ColorValuesView: View {
    @Binding var color: HSBAColor
    var colorHistory: ColorHistory
    var alignment: Alignment
    var oppositeAlignment: Alignment {
        if alignment == .leading { .trailing } else { .leading }
    }
    @State private var contentHeight: CGFloat = 0
    @State private var isOpen: Bool = true
    @State private var panelWidth = Layout.panelWidth
    @State private var dragStartWidth: CGFloat? = nil
    
    init(alignment: HorizontalAlignment, color: Binding<HSBAColor>, colorHistory: ColorHistory) {
        var alignment = alignment == .center ? .leading : alignment
        self.alignment = Alignment(horizontal: alignment, vertical: .center)
        _color = color
        self.colorHistory = colorHistory
    }
    
    private func storeColor() { colorHistory.add(color) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                colorPreview
                
                hexValue
                
                opacityValue
                
                ColorDisclosureGroup(title: "HSV", value: color.hsvString, content: hsvValues)
                
                ColorDisclosureGroup(title: "HSL", value: color.hslString, content: hslValues)
                
                ColorDisclosureGroup(title: "RGB", value: color.rgbString, content: rgbValues)
                
                ColorDisclosureGroup(title: "CMYK", value: color.cmykString, content: cmykValues)
                
                ColorHistoryView(color: $color, colorHistory: colorHistory)
                
            }
            .background {
                Color.clear
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: {
                        contentHeight = $0
                    }
            }
            .frame(width: panelWidth)
        }
        .frame(width: isOpen ? panelWidth : 0)
        .scrollIndicators(.hidden)
        .clipped()
        .padding(isOpen ? Layout.panelInnerPadding : 0)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .stroke(.separator, lineWidth: 1)
        }
        .overlay(alignment: oppositeAlignment) {
            dragHandle
        }
        .overlay(alignment: oppositeAlignment) {
            togglePanelButton(alignment: alignment, isOpen: $isOpen, panelWidth: $panelWidth)
        }
        .padding(isOpen ? Layout.panelOuterPadding : 0)
    }
}

extension ColorValuesView {
    private var dragHandle: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 4)
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
                        var delta = alignment == .trailing
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
                    .stroke(.tertiary, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .trailing) {
                EyeDropperView(pickedColor: $color, storeColor: { colorHistory.add($0) })
                    .offset(x: 30)
            }
            .padding(.bottom, 10)
    }
    
    private var hexValue: some View {
        ColorValueLabelView(label: "HEX", value: $color.hex, inputType: .hex, storeColor: storeColor)
            .padding(.horizontal, 4)
    }
    
    private var hsvValues: some View {
        section {
            ColorValueLabelView(label: "H", value: $color.hue, inputType: .degrees, storeColor: storeColor)
            ColorValueLabelView(label: "S", value: $color.saturation, inputType: .percentage, storeColor: storeColor)
            ColorValueLabelView(label: "V", value: $color.brightness, inputType: .percentage, storeColor: storeColor)
        }
    }
    
    private var hslValues: some View {
        section {
            ColorValueLabelView(label: "H", value: $color.hsl.hue, inputType: .degrees, storeColor: storeColor)
            ColorValueLabelView(label: "S", value: $color.hsl.saturation, inputType: .percentage, storeColor: storeColor)
            ColorValueLabelView(label: "L", value: $color.hsl.lightness, inputType: .percentage, storeColor: storeColor)
        }
    }
    
    private var rgbValues: some View {
        section {
            ColorValueLabelView(label: "R", value: $color.rgb.red, inputType: .numerical, storeColor: storeColor)
            ColorValueLabelView(label: "G", value: $color.rgb.green, inputType: .numerical, storeColor: storeColor)
            ColorValueLabelView(label: "B", value: $color.rgb.blue, inputType: .numerical, storeColor: storeColor)
        }
    }
    
    private var cmykValues: some View {
        section {
            ColorValueLabelView(label: "C", value: $color.cmyk.cyan, inputType: .percentage, storeColor: storeColor)
            ColorValueLabelView(label: "M", value: $color.cmyk.magenta, inputType: .percentage, storeColor: storeColor)
            ColorValueLabelView(label: "Y", value: $color.cmyk.yellow, inputType: .percentage, storeColor: storeColor)
            ColorValueLabelView(label: "K", value: $color.cmyk.key, inputType: .percentage, storeColor: storeColor)
        }
    }
    
    private var opacityValue: some View {
        ColorValueLabelView(label: "Opacity", value: $color.alpha, inputType: .percentage)
            .padding(.horizontal, 4)
    }
    
    private func section<Content: View> (@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 3) {
            content()
                .padding(.horizontal, 4)
        }
    }

    private struct togglePanelButton: View {
        var alignment: Alignment
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
        var offset: CGFloat { isOpen ? 10 : 25}
        
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
                    if !isOpen {
                        panelWidth = 200
                    }
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isOpen.toggle()
                    }
                }
                .onHover { isHoveringTogglePanel = $0 }
                .animation(.easeInOut(duration: 0.1), value: isHoveringTogglePanel)
        }
    }
    
    private struct ColorValueLabelView: View {
        let label: String
        let inputType: InputType
        @Binding var value: String
        @State private var text: String
        let storeColor: () -> Void
        @FocusState private var isFocused: Bool
        @State private var isHovering: Bool = false
        
        init(label: String, value: Binding<CGFloat>, inputType: InputType, storeColor: @escaping () -> Void = {}) {
            let valueStr = inputType.format(value.wrappedValue)
            self.label = label
            self.inputType = inputType
            self._value = Binding(
                get: { inputType.format(value.wrappedValue) },
                set: { value.wrappedValue = inputType.normalize($0) }
            )
            self.storeColor = storeColor
            self._text = .init(initialValue: valueStr)
        }
        
        init(label: String, value: Binding<UInt32>, inputType: InputType, storeColor: @escaping () -> Void) {
            let valueStr = inputType.format(value.wrappedValue)
            self.label = label
            self.inputType = inputType
            self._value = Binding(
                get: { String(format: inputType.format, value.wrappedValue) },
                set: { value.wrappedValue = UInt32(inputType.normalize($0)) }
            )
            self.storeColor = storeColor
            self._text = .init(initialValue: valueStr)
        }
        
        var body: some View {
            HStack {
                Text(label)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .onTapGesture { isFocused.toggle() }
                
                Spacer()
                
                TextField("", text: $text)
                    .multilineTextAlignment(.leading)
                    .onKeyPress(keys: [.upArrow, .downArrow], action: handleArrows)
                    .onSubmit(submit)
                    .onExitCommand(perform: cancel)
                    .focused($isFocused)
                    .onChange(of: value, perform: updateText)
                    .onChange(of: isFocused, perform: blur)
                    .onHover { isHovering = $0 }
                    .background(ScrollWheelMonitor(onScroll: handleScroll, storeColor: storeColor))
                    .frame(width: inputType == .hex ? 80 : 50)
            }
        }
        
        private func updateText(newValue: String) {
            isFocused = false
            text = newValue
        }
        
        private func handleArrows(press: KeyPress) -> KeyPress.Result {
            guard !(inputType == .hex) else { return .handled }
            guard isFocused else { return .handled }
            
            var step = press.key == .upArrow ? 1.0 : -1.0
            if press.modifiers.contains([.command]) {
                let normalizedValue = (step + 1) * 0.5
                text = inputType.format(normalizedValue)
                return .handled
            }
            
            var current = inputType.normalize(text) * CGFloat(inputType.multiplier)
            current = inputType.normalize(String(format: inputType.format, current + step))
            text = inputType.format(current)
            
            return .handled
        }
        
        private func handleScroll(_: CGPoint, event: NSEvent) {
            guard inputType != .hex else { return }
            guard isHovering else { return }
            let step = event.scrollingDeltaY > 0 ? 1.0 : -1.0
            
            var current = inputType.normalize(text) * CGFloat(inputType.multiplier)
            current = inputType.normalize(String(format: inputType.format, current + step))
            value = inputType.format(current)
        }
        
        private func blur(isFocused: Bool) {
            if !isFocused && inputType.parse(text) != inputType.parse(value) {
                commit()
            }
        }
        
        private func submit() {
            commit()
            isFocused = false
        }
        
        private func commit() {
            value = text
            text = value
            storeColor()
        }
        
        private func cancel() {
            if isFocused {
                text = value
                isFocused = false
            }
        }
    }
    
    private struct ColorDisclosureGroup<Content: View>: View {
        @State private var isOpen: Bool = false
        let title: String
        let value: String
        var content: Content
        
        var body: some View {
            HStack {
                Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                    .frame(width: 15, height: 10)
                    .bold()
                Text(title)
                    .fontWeight(.bold)
                Spacer()
                Text(!isOpen ? value : "")
            }
            .onTapGesture { isOpen.toggle() }
            .padding(.top, 8)
            
            if isOpen {
                content
            }
        }
    }
}

#Preview {
    ColorValuesView(alignment: .trailing, color: .constant(HSBAColor(with: .orange)), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
