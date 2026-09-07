//
//  ColorComponentField.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 13/08/2026.
//

import SwiftUI

private enum Layout {
    static let textFieldHeight: CGFloat = 24
    static let textFieldCornerRadius: CGFloat = 6
    static let textFieldWidth: CGFloat = 50
    static let hexTextFieldWidth: CGFloat = 70
    
    static let stepperSpacing: CGFloat = 2
    static let stepperHeight: CGFloat = 20 + Layout.stepperSpacing
    static let stepperWidth: CGFloat = 14
    
    static let sliderThumbWidth: CGFloat = 5
    static let sliderThumbHeight: CGFloat = 15
}

@MainActor
struct ColorComponentField<T: ColorComponentNumeric>: View {
    @Environment(\.scrollWheelRouter) private var scrollWheelRouter
    @Binding var value: T
    @State private var text: String
    @State private var isHovering: Bool = false
    @FocusState private var isFocused: Bool
    private var valueString: String { inputType.format(value.cgFloatValue) }
    
    let inputType: InputType
    let storeColor: () -> Void
    
    init(value: Binding<T>, inputType: InputType, storeColor: @escaping () -> Void = {}, sliderWidth: CGFloat = 0) {
        self.inputType = inputType
        self._value = value
        self.storeColor = storeColor
        self._text = .init(initialValue: inputType.format(value.wrappedValue.cgFloatValue))
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if inputType != .hex {
                ColorComponentSlider(
                    normalized: Binding(
                        get: { isFocused ? inputType.normalize(text) ?? value.cgFloatValue : value.cgFloatValue },
                        set: {
                            if isFocused {
                                text = inputType.format($0)
                            } else {
                                value = T(value: $0)
                            }
                        }
                    ),
                    storeColor: storeColor
                )
            }
            
            ZStack(alignment: .leading) {
                ColorComponentTextField(
                    text: $text,
                    isFocused: _isFocused,
                    inputType: inputType,
                    handleArrows: handleArrows,
                    submitText: submitText,
                    cancelField: cancelField,
                    updateText: updateText
                )
                .equatable()
                
                Text(valueString)
                    .frame(width: inputType == .hex ? Layout.hexTextFieldWidth : Layout.textFieldWidth, height: Layout.textFieldHeight)
                    .contentShape(Rectangle())
                    .onTapGesture { isFocused = true }
                    .background {
                        RoundedRectangle(cornerRadius: Layout.textFieldCornerRadius)
                            .fill(.background.secondary)
                            .stroke(.separator, lineWidth: 1)
                    }
                    .opacity(isFocused ? 0 : 1)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering { NSCursor.iBeam.set() } else { NSCursor.arrow.set() }
                if hovering {
                    if inputType != .hex {
                        scrollWheelRouter.scrollHandler = handleScroll
                    }
                } else {
                    scrollWheelRouter.scrollHandler = nil
                }
            }
            
            if inputType != .hex { ColorComponentStepper(isFocused: isFocused, storeColor: storeColor, stepValue: stepValue(by:)) }
        }
    }
    
    struct ColorComponentTextField: View {
        @Binding var text: String
        @FocusState var isFocused: Bool
        let inputType: InputType
        let handleArrows: (KeyPress) -> KeyPress.Result
        let submitText: () -> Void
        let cancelField: () -> Void
        let updateText: () -> Void
        
        var body: some View {
            TextField("", text: $text)
                .multilineTextAlignment(.center)
                .frame(width: inputType == .hex ? Layout.hexTextFieldWidth : Layout.textFieldWidth, height: Layout.textFieldHeight)
                .textFieldStyle(.plain)
                .onKeyPress(keys: [.upArrow, .downArrow], action: handleArrows)
                .onSubmit(submitText)
                .onExitCommand(perform: cancelField)
                .focused($isFocused)
                .onChange(of: isFocused, updateText)
                .background {
                    RoundedRectangle(cornerRadius: Layout.textFieldCornerRadius)
                        .fill(.background.secondary)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
                .opacity(isFocused ? 1 : 0)
        }
    }
    
    private struct ColorComponentStepper: View {
        @State var isFocused: Bool
        var storeColor: () -> Void
        var stepValue: (CGFloat) -> Void
        @State private var hoveringChevron: CGFloat? = nil
        @State private var timer: Timer? = nil
        @State private var activeStep: CGFloat? = nil
        
        var body: some View {
            VStack(spacing: Layout.stepperSpacing) {
                Image(systemName: "chevron.up")
                    .background(RoundedRectangle(cornerRadius: 6).fill(activeStep == 1 ? .gray.opacity(0.2) : .clear))
                Image(systemName: "chevron.down")
                    .background(RoundedRectangle(cornerRadius: 6).fill(activeStep == -1 ? .gray.opacity(0.2) : .clear))
            }
            .frame(width: Layout.stepperWidth, height: Layout.stepperHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let bounds = CGRect(x: 0, y: 0, width: Layout.stepperWidth, height: Layout.stepperHeight)
                        guard bounds.contains(value.location) else {
                            activeStep = nil
                            stopStepping()
                            return
                        }
                        let step: CGFloat = value.location.y < Layout.stepperHeight * 0.5 ? 1 : -1
                        if activeStep != step {
                            activeStep = step
                            startStepping(step)
                        }
                    }
                    .onEnded { _ in
                        activeStep = nil
                        stopStepping()
                    }
            )
        }
        
        private func startStepping(_ step: CGFloat) {
            stopStepping()
            stepValue(step)
            if !isFocused { storeColor() }
            let t = Timer(timeInterval: 0.15, repeats: true) { _ in
                stepValue(step)
                if !isFocused { storeColor() }
            }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
        
        private func stopStepping() {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private struct ColorComponentSlider: View {
        @Binding var normalized: CGFloat
        var storeColor: () -> Void
        @State private var width: CGFloat = 0
        @State private var isDragging: Bool = false
        
        var body: some View {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(normalized * width, 0))
            }
            .frame(height: 5)
            .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.clear)
                        .frame(width: Layout.sliderThumbWidth, height: Layout.sliderThumbHeight)
                        .background {
                            ZStack {
                                if isDragging {
                                    Capsule().glassEffect(.clear, in: Capsule())
                                } else {
                                    Capsule().fill(.white)
                                }
                            }
                        }
                        .scaleEffect(isDragging ? 1.25 : 1)
                        .animation(.easeInOut(duration: 0.1), value: isDragging)
                        .offset(x: width * normalized - (Layout.sliderThumbWidth * 0.5))
                        .gesture(dragGesture)
                }
                .position(x: width * 0.5, y: Layout.textFieldHeight * 0.5)
                .gesture(dragGesture)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
        
        var dragGesture: some Gesture {
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged {
                    if !isDragging { isDragging = true }
                    normalized = ($0.location.x / width).clamped(to: 0...1)
                }
                .onEnded { _ in
                    isDragging = false
                    storeColor()
                }
        }
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
        
        let newValue = increaseValue(inputType.normalize(text) ?? value.cgFloatValue, by: step)
        text = inputType.format(newValue)
        
        return .handled
    }
    
    private func handleScroll(event: NSEvent) {
        guard inputType != .hex else { return }
        let delta = event.scrollingDeltaY > 0 ? 1.0 : -1.0
        stepValue(by: delta)
    }
    
    private func updateText() { text = valueString }
    
    private func submitText() {
        commitColor()
        isFocused = false
    }
    
    private func commitColor() {
        guard let normalized = inputType.normalize(text) else {
            text = valueString
            return
        }
        value = T(value: normalized)
        text = valueString
        storeColor()
    }
    
    private func cancelField() {
        if isFocused {
            text = valueString
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
            let newValue = increaseValue(inputType.normalize(text) ?? value.cgFloatValue, by: amount)
            text = inputType.format(newValue)
        } else {
            let newValue = increaseValue(value.cgFloatValue, by: amount)
            value = T(value: newValue)
        }
    }
}

struct ColorComponentFieldContainer<Content: View>: View {
    let component: String
    @ViewBuilder let componentField: () -> Content
    var body: some View {
        HStack {
            Text("\(component)")
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            componentField()
        }
    }
}

extension ColorComponentField.ColorComponentTextField: @MainActor Equatable {
    static func == (a: Self, b: Self) -> Bool {
        a.text == b.text && a.inputType == b.inputType && a.isFocused == b.isFocused
    }
}
