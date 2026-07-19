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
    static let panelOuterPadding: CGFloat = 6
    static let panelCornerRadius: CGFloat = 12
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
                
                hsvValues
                
                hslValues

                rgbValues
                
                cmykValues
                
                opacityValue
                
                Divider()
                
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
        }
        .frame(width: isOpen ? panelWidth : 0)
        .scrollIndicators(.hidden)
        .clipped()
        .padding(isOpen ? Layout.panelInnerPadding : 0)
        .background {
            RoundedRectangle(cornerRadius: Layout.panelCornerRadius)
                .fill(.ultraThickMaterial)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        }
        .overlay(alignment: oppositeAlignment) {
            if isOpen {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                var direction = alignment == .trailing ? -value.translation.width : value.translation.width
                                panelWidth += direction
                                panelWidth = max(100, min(500, panelWidth))
                            }
                    )
            }
        }
        .overlay(alignment: oppositeAlignment, content: { togglePanelButton(alignment: alignment, isOpen: $isOpen) })
        .padding(Layout.panelOuterPadding)
    }
}

extension ColorValuesView {
    private var colorPreview: some View {
        ColorExample(color: color)
            .frame(width: 80, height: 80)
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
        section {
            ColorValueLabelView(label: "HEX", value: $color.hex, inputType: .hex, storeColor: storeColor)
        }
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
        section {
            ColorValueLabelView(label: "Opacity", value: $color.alpha, inputType: .percentage)
        }
    }
    
    private func section<Content: View> (@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 4) {
            Divider()
            content()
        }
    }

    private struct togglePanelButton: View {
        var alignment: Alignment
        @Binding var isOpen: Bool
        @State private var isHoveringTogglePanel: Bool = false
        var chevron: String {
            if alignment == .trailing {
                isOpen ? "chevron.left" : "chevron.right"
            } else {
                isOpen ? "chevron.right" : "chevron.left"
            }
        }
        
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
                .offset(x: alignment == .trailing ? -10 : 10)
                .onTapGesture {
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
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .onTapGesture { isFocused.toggle() }
                Spacer()
                TextField("", text: $text)
                    .foregroundColor(isFocused ? .primary : .secondary)
                    .multilineTextAlignment(.trailing)
                    .onKeyPress(keys: [.upArrow, .downArrow], action: handleArrows)
                    .onSubmit(submit)
                    .onExitCommand(perform: cancel)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onChange(of: value, perform: updateText)
                    .onChange(of: isFocused, perform: blur)
                    .onHover { isHovering = $0 }
                    .background(ScrollWheelMonitor(onScroll: handleScroll, storeColor: storeColor))
                    .frame(width: 75)
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
}

#Preview {
    ColorValuesView(alignment: .trailing, color: .constant(HSBAColor(with: .orange)), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
