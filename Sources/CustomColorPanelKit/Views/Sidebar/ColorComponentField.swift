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
    
    static let sliderTrackHeight: CGFloat = 5
    static let sliderThumbSize: CGFloat = 12
}

@MainActor
struct ColorComponentField<T: ColorComponentNumeric>: View {
    private var scrollWheelRouter = ScrollWheelRouter.shared
    @Binding var value: T
    @State private var text: String
    @State private var isHovering: Bool = false
    @FocusState private var isFocused: Bool
    private var valueString: String { inputType.format(value.cgFloatValue) }
    
    let inputType: InputType
    let label: String
    let storeColor: () -> Void
    
    init(value: Binding<T>, inputType: InputType, label: String, storeColor: @escaping () -> Void = {}) {
        self.inputType = inputType
        self._value = value
        self.label = label
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
                    inputType: inputType,
                    label: label,
                    storeColor: isFocused ? {} : storeColor
                )
                .padding(.trailing, 4)
            }
            
            ZStack(alignment: .leading) {
                ColorComponentTextField(
                    label: label,
                    text: $text,
                    isFocused: _isFocused,
                    inputType: inputType,
                    handleArrows: handleArrows,
                    submitText: submitText,
                    cancelField: cancelField
                )
                .equatable()
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    if inputType != .hex {
                        scrollWheelRouter.scrollHandler = handleScroll
                    }
                } else {
                    scrollWheelRouter.scrollHandler = nil
                }
            }
            
            if inputType != .hex {
                ColorComponentStepper(
                    storeColor: isFocused ? {} : storeColor,
                    stepValue: stepValue
                )
                .equatable()
                .padding(.trailing, 8)
            }
        }
        .onChange(of: value.cgFloatValue) {
            if !isFocused { text = inputType.format(value.cgFloatValue) }
        }
        .onChange(of: isFocused) {
            if !isFocused { text = inputType.format(value.cgFloatValue) }
        }
    }
    
    struct ColorComponentTextField: View {
        let label: String
        @Binding var text: String
        @FocusState var isFocused: Bool
        let inputType: InputType
        let handleArrows: (KeyPress) -> KeyPress.Result
        let submitText: () -> Void
        let cancelField: () -> Void
        
        var body: some View {
            TextField("", text: $text)
                .multilineTextAlignment(.center)
                .frame(width: inputType == .hex ? Layout.hexTextFieldWidth : Layout.textFieldWidth, height: Layout.textFieldHeight)
                .textFieldStyle(.plain)
                .onKeyPress(keys: [.upArrow, .downArrow], action: handleArrows)
                .onSubmit(submitText)
                .onExitCommand(perform: cancelField)
                .focused($isFocused)
                .clipped()
                .background {
                    RoundedRectangle(cornerRadius: Layout.textFieldCornerRadius)
                        .fill(.background.secondary)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.textFieldCornerRadius)
                        .fill(.clear)
                        .stroke(isFocused ? Color.accentColor : Color.gray.opacity(0.25), lineWidth: isFocused ? 2 : 1)
                        .animation(.easeInOut(duration: 0.1), value: isFocused)
                }
                .accessibilityLabel(label)
        }
    }
    
    private struct ColorComponentStepper: View, @MainActor Equatable {
        var storeColor: () -> Void
        var stepValue: (CGFloat) -> Void
        
        var body: some View {
            Stepper(
                "",
                onIncrement: {
                    stepValue(1)
                    storeColor()
                },
                onDecrement:  {
                    stepValue(-1)
                    storeColor()
                }
            )
            .frame(width: Layout.stepperWidth, height: Layout.stepperHeight)
            .accessibilityHidden(true)
        }
        
        static func == (a: Self, b: Self) -> Bool { true }
    }
    
    private struct ColorComponentSlider: View {
        @Binding var normalized: CGFloat
        let inputType: InputType
        let label: String
        var storeColor: () -> Void
        
        @State private var width: CGFloat = 0
        
        @GestureState private var isDragging = false
        
        var body: some View {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary)
                    .frame(height: Layout.sliderTrackHeight)
                
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(normalized * width, 0), height: Layout.sliderTrackHeight)
                
                thumb
                
            }
            .frame(height: Layout.sliderTrackHeight)
            .frame(maxWidth: .infinity)
            .position(x: width * 0.5, y: Layout.textFieldHeight * 0.5)
            .gesture(dragGesture)
            .accessibilityRepresentation {
                Slider(
                    value: Binding(
                        get: { normalized },
                        set: {
                            normalized = $0
                            storeColor()
                        }
                    ),
                    in: 0...1,
                    step: 1 / CGFloat(inputType.multiplier)
                )
                    .accessibilityLabel(label)
                    .accessibilityValue(inputType.format(normalized))
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
        
        private var thumb: some View {
            Circle()
                .fill(isDragging ? Color.clear : .white)
                .frame(width: Layout.sliderThumbSize, height: Layout.sliderThumbSize)
                .background {
                    if isDragging {
                        Capsule().fill(.clear).glassEffect(.clear, in: .capsule)
                    }
                }
                .scaleEffect(isDragging ? 1.25 : 1)
                .shadow(radius: 1)
                .animation(.easeInOut(duration: 0.1), value: isDragging)
                .offset(x: width * normalized - (Layout.sliderThumbSize * 0.5))
                .gesture(dragGesture)
        }
        
        private var dragGesture: some Gesture {
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isDragging) { _, state, _ in state = true }
                .onChanged {
                    guard width > 0 else { return }
                    normalized = ($0.location.x / width).clamped(to: 0...1)
                }
                .onEnded { _ in storeColor() }
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
