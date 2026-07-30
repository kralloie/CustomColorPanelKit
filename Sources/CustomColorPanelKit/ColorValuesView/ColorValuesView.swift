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

struct ColorValuesView: View {
    @Binding var color: HSBAColor
    var colorHistory: ColorHistory
    var alignment: Alignment
    var oppositeAlignment: Alignment {
        if alignment == .leading { .trailing } else { .leading }
    }
    @State private var isOpen: Bool = true
    @State private var panelWidth = Layout.panelWidth
    @State private var dragStartWidth: CGFloat? = nil
    
    init(alignment: HorizontalAlignment, color: Binding<HSBAColor>, colorHistory: ColorHistory) {
        let alignment = alignment == .center ? .leading : alignment
        self.alignment = Alignment(horizontal: alignment, vertical: .center)
        _color = color
        self.colorHistory = colorHistory
    }
    
    private func storeColor() { colorHistory.add(color) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                colorPreview
                
                hexAndAlphaValues
                
                ColorDisclosureGroup(title: "HSV", value: color.hsvString, content: hsvValues)
                
                ColorDisclosureGroup(title: "HSL", value: color.hsl.string, content: hslValues)
                
                ColorDisclosureGroup(title: "RGB", value: color.rgb.string, content: rgbValues)
                
                ColorDisclosureGroup(title: "CMYK", value: color.cmyk.string, content: cmykValues)
                
                ColorHistoryView(color: $color, colorHistory: colorHistory)
                
            }
            .padding(Layout.panelInnerPadding)
            .frame(width: panelWidth)
        }
        .frame(width: isOpen ? panelWidth : 0)
        .scrollIndicators(.hidden)
        .clipped()
        .background {
            RoundedRectangle(cornerRadius: Layout.sidebarCornerRadius)
                .fill(.regularMaterial)
                .stroke(.separator, lineWidth: 1)
        }
        .overlay(alignment: oppositeAlignment) {
            dragHandle
        }
        .overlay(alignment: oppositeAlignment) {
            TogglePanelButton(alignment: alignment, isOpen: $isOpen, panelWidth: $panelWidth)
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
    
    private var hexAndAlphaValues: some View {
        @ViewBuilder var fields: some View {
            HStack {
                Text("HEX:")
                    .lineLimit(1)
                    .bold()
                ColorComponentField(value: $color.hex, inputType: .hex, storeColor: storeColor)
            }
            HStack {
                Text("Alpha:")
                    .lineLimit(1)
                    .bold()
                ColorComponentField(value: $color.alpha, inputType: .percentage)
            }
        }
        return ViewThatFits(in: .horizontal) {
            HStack { fields }
            VStack { fields }
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
        VStack(spacing: 3) {
            content()
                .padding(.horizontal, 4)
        }
    }
    
    private struct ColorComponentFieldContainer<Content: View>: View {
        let component: String
        @ViewBuilder let componentField: () -> Content
        var body: some View {
            HStack {
                Spacer()
                Text("\(component):")
                    .lineLimit(1)
                componentField()
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
    
    private struct ColorComponentField<T: ColorComponentNumeric>: View {
        @Binding var value: String
        @Binding var valueBinding: T
        
        @State private var text: String
        @State private var isHovering: Bool = false
        @FocusState private var isFocused: Bool
        
        let inputType: InputType
        let storeColor: () -> Void
        
        init(value: Binding<T>, inputType: InputType, storeColor: @escaping () -> Void = {}) {
            self.inputType = inputType
            self._value = Binding(
                get: { inputType.format(value.wrappedValue.cgFloatValue) },
                set: { value.wrappedValue = T(value: inputType.normalize($0)) }
            )
            self._valueBinding = value
            self.storeColor = storeColor
            self._text = .init(initialValue: inputType.format(value.wrappedValue.cgFloatValue))
        }
        
        var body: some View {
            HStack(spacing: 0) {
                TextField("", text: $text)
                    .multilineTextAlignment(.leading)
                    .onKeyPress(keys: [.upArrow, .downArrow], action: handleArrows)
                    .onSubmit(submitText)
                    .onExitCommand(perform: cancelField)
                    .focused($isFocused)
                    .onChange(of: value, perform: updateText)
                    .onChange(of: isFocused, perform: blurField)
                    .onHover { isHovering = $0 }
                    .background {
                        if inputType != .hex {
                            ScrollWheelMonitor(isHovering: isHovering, onScroll: handleScroll, storeColor: storeColor)
                        }
                    }
                    .frame(width: inputType == .hex ? 70 : 50)
                
                if inputType != .hex { stepper }
            }
        }
        
        private var stepper: some View {
            Stepper(
                onIncrement: {
                    stepValue(by: 1)
                    if !isFocused { storeColor() }
                },
                onDecrement: {
                    stepValue(by: -1)
                    if !isFocused { storeColor() }
                }
            ) {
                Text("")
            }
        }
        
        private func updateText(newValue: String) {
            isFocused = false
            text = newValue
        }
        
        private func handleArrows(press: KeyPress) -> KeyPress.Result {
            guard !(inputType == .hex) else { return .handled }
            guard isFocused else { return .handled }
            
            let step = press.key == .upArrow ? 1.0 : -1.0
            if press.modifiers.contains([.command]) {
                let normalizedValue = (step + 1) * 0.5
                text = inputType.format(normalizedValue)
                return .handled
            }
            
            let newValue = increaseValue(inputType.normalize(text), by: step)
            text = inputType.format(newValue)
            
            return .handled
        }
        
        private func handleScroll(_: CGPoint, event: NSEvent) {
            guard inputType != .hex else { return }
            guard isHovering else { return }
            let delta = event.scrollingDeltaY > 0 ? 1.0 : -1.0
            stepValue(by: delta)
        }
        
        private func blurField(isFocused: Bool) {
            if !isFocused && inputType.parse(text) != inputType.parse(value) {
                commitColor()
            }
        }
        
        private func submitText() {
            commitColor()
            isFocused = false
        }
        
        private func commitColor() {
            value = text
            text = value
            storeColor()
        }
        
        private func cancelField() {
            if isFocused {
                text = value
                isFocused = false
            }
        }
        
        private func increaseValue(_ value: CGFloat, by step: CGFloat) -> CGFloat {
            let steppedValue = (value + step / CGFloat(inputType.multiplier))
            if inputType == .degrees {
                let value = steppedValue.truncatingRemainder(dividingBy: 1)
                return value < 0 ? value + 1 : value
            } else {
                return steppedValue.clamped(to: 0...1)
            }
        }
        
        private func stepValue(by amount: CGFloat) {
            if isFocused {
                let newValue = increaseValue(inputType.normalize(text), by: amount)
                text = inputType.format(newValue)
            } else {
                let newValue = increaseValue(valueBinding.cgFloatValue, by: amount)
                valueBinding = T(value: newValue)
            }
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
                    Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                        .frame(width: 15, height: 10)
                        .bold()
                    Text("\(title):")
                        .lineLimit(1)
                        .fontWeight(.bold)
                    Spacer()
                    Text(!isOpen ? value : "")
                }
                .contentShape(Rectangle())
                .onTapGesture { isOpen.toggle() }
                .padding(.top, 8)
                
                if isOpen { content }
            }
        }
    }
}

#Preview {
    ColorValuesView(alignment: .trailing, color: .constant(HSBAColor(with: .orange)), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
