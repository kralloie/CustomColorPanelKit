//
//  ColorComponentField.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 13/08/2026.
//

import SwiftUI

/// Layout values for ``ColorComponentField``
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

/// A row that represents a single color component in the sidebar.
/// Consists of a label for the component letter, a slider, a text field and a stepper as controls for the component value.
@MainActor
struct ColorComponentField<T: ColorComponentNumeric>: View, @MainActor Equatable {
    /// The scroll router instance to pass the scroll handler to.
    @Environment(ScrollWheelRouter.self) private var scrollWheelRouter
    /// The current color component value.
    let value: T
    /// Gets the live value of the component.
    let getValue: () -> T
    /// Updates the color component value.
    let setValue: (T) -> Void
    /// The text displayed on the text field.
    @State private var text: String = ""
    /// Whether the text field is focused.
    @FocusState private var isFocused: Bool
    /// The computed formatted string for `value`.
    private var valueString: String { inputType.format(value.cgFloatValue) }
    /// The format of this component text representation.
    let inputType: InputType
    /// The label of the component.
    let label: LocalizedStringResource
    /// A closure that stores the current color to history.
    let storeColor: () -> Void
    
    private var textBinding: Binding<String> {
        Binding(
            get: { isFocused ? text : valueString },
            set: { text = $0 }
        )
    }
    
    init(
        value: T,
        getValue: @escaping () -> T,
        setValue: @escaping (T) -> Void,
        inputType: InputType,
        label: LocalizedStringResource,
        storeColor: @escaping () -> Void = {}
    ) {
        self.value = value
        self.getValue = getValue
        self.setValue = setValue
        self.inputType = inputType
        self.label = label
        self.storeColor = storeColor
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
                                setValue(T(value: $0))
                            }
                        }
                    ),
                    inputType: inputType,
                    label: label,
                    storeColor: { if !isFocused { storeColor() } }
                )
                .padding(.trailing, 4)
            }
            
            ZStack(alignment: .leading) {
                ColorComponentTextField(
                    label: label,
                    text: textBinding,
                    isFocused: _isFocused,
                    inputType: inputType,
                    handleArrows: handleArrows,
                    submitText: commitColor,
                    cancelField: cancelField
                )
                .equatable()
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering && inputType != .hex {
                    scrollWheelRouter.scrollHandler = handleScroll
                } else {
                    scrollWheelRouter.scrollHandler = nil
                }
            }
            .onDisappear { scrollWheelRouter.scrollHandler = nil }
            
            if inputType != .hex {
                ColorComponentStepper(
                    storeColor: storeColor,
                    stepValue: stepValue,
                    isFocused: isFocused
                )
                .equatable()
                .padding(.trailing, 8)
            }
        }
        .onChange(of: isFocused) {
            if isFocused { text = valueString }
        }
    }
    
    /// The text field for the component value.
    struct ColorComponentTextField: View, @MainActor Equatable {
        /// The label of the component used for accessibility.
        let label: LocalizedStringResource
        /// A binding to the text of this field.
        @Binding var text: String
        /// Whether the field is focused.
        @FocusState var isFocused: Bool
        /// The format of this component text representation.
        let inputType: InputType
        /// Handles arrows pressed while editing the text field.
        let handleArrows: (KeyPress) -> KeyPress.Result
        /// Called when when text field is submitted.
        let submitText: () -> Void
        /// Called when text field is cancelled.
        let cancelField: () -> Void
        
        var body: some View {
            TextField(text: $text) {
                EmptyView()
            }
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
        
        /// The Equatable implementation for avoiding unnecessary updates.
        static func == (a: Self, b: Self) -> Bool {
            a.text == b.text && a.inputType == b.inputType && a.isFocused == b.isFocused
        }
    }
    
    /// The stepper control for the component value.
    private struct ColorComponentStepper: View, @MainActor Equatable {
        /// Called after a step is pressed if text field is not focused.
        var storeColor: () -> Void
        /// Steps the component value by the passed parameter.
        var stepValue: (CGFloat) -> Void
        /// Whether the text field is focused.
        var isFocused: Bool
        
        var body: some View {
            Stepper {
                EmptyView()
            } onIncrement: {
                stepValue(1)
                if !isFocused { storeColor() }
            } onDecrement:  {
                stepValue(-1)
                if !isFocused { storeColor() }
            }
            .frame(width: Layout.stepperWidth, height: Layout.stepperHeight)
            .accessibilityHidden(true)
        }
        
        static func == (a: Self, b: Self) -> Bool { a.isFocused == b.isFocused }
    }
    
    /// The slider control for the component value.
    private struct ColorComponentSlider: View {
        @Environment(\.accessibilityEnabled) private var accessibilityEnabled
        /// A custom binding that gets the normalized value from the text so it is between 0.0 and 1.0
        /// setting the value if text field is not focused and the text if the text field is focused.
        @Binding var normalized: CGFloat
        /// The format of this component text representation.
        let inputType: InputType
        /// The label of the component used for accessibility.
        let label: LocalizedStringResource
        /// Stores the edited color after the slider drag ends if the text field is not focused.
        var storeColor: () -> Void
        
        /// The task running the animation that starts when the slider is pressed.
        @State private var valueAnimation: Task<Void, Never>? = nil
        /// The available size reported by `onGeometryChange`.
        @State private var size: CGSize = .zero
        /// Whether the current drag has already reported its first change, so only the press animates.
        @State private var gestureBegan: Bool = false
        /// Whether the slider is being dragged, updated by the `dragGesture`.
        @GestureState private var isDragging = false
        
        var body: some View {
            if accessibilityEnabled {
                slider
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
            } else {
                slider
            }
        }
        
        var slider: some View {
            ZStack(alignment: .center) {
                Capsule()
                    .fill(Color.primary)
                    .frame(width: size.width, height: Layout.sliderTrackHeight)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: max(normalized * size.width, 0), height: Layout.sliderTrackHeight)
                    }
                
                thumb
                
            }
            .frame(height: Layout.sliderTrackHeight)
            .frame(maxWidth: .infinity)
            .position(x: size.width * 0.5, y: Layout.textFieldHeight * 0.5)
            .gesture(dragGesture)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        }
        
        /// Indicates the slider current position.
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
                .offset(x: (size.width - Layout.sliderThumbSize) * (normalized - 0.5))
        }
        
        /// The gesture that handles dragging inside the slider.
        ///
        /// The pointer is clamped when it leaves the slider shape.
        private var dragGesture: some Gesture {
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isDragging) { _, state, _ in state = true }
                .onChanged {
                    guard size.width > 0 && size.width > size.height else { return }
                    let isFirst = !gestureBegan
                    if !gestureBegan { gestureBegan = true }
                    
                    let travel = size.width - Layout.sliderThumbSize
                    let target = (($0.location.x - Layout.sliderThumbSize * 0.5) / travel).clamped(to: 0...1)
                    
                    if isFirst {
                        animateValue($normalized, to: target, valueAnimation: $valueAnimation)
                    } else {
                        valueAnimation?.cancel()
                        normalized = target
                    }
                }
                .onEnded { _ in
                    gestureBegan = false
                    Task { @MainActor in
                        await valueAnimation?.value
                        storeColor()
                    }
                }
        }
    }
    
    /// Modifies the text field value by pressing the up and down arrows while the text field is focused.
    ///
    /// Pressing the Command key while pressing the arrows will go to the minimum and maximum values directly.
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
    
    /// Handles the scrolling on when the cursor is hovering the text field.
    /// Modifies the text content if the text field is focused and the component value if the text field is not focused.
    private func handleScroll(event: NSEvent) -> Bool {
        guard event.scrollingDeltaY != 0 else { return false }
        guard inputType != .hex else { return false }
        let delta = event.scrollingDeltaY > 0 ? 1.0 : -1.0
        stepValue(by: delta)
        return !isFocused
    }
    
    /// Turns the text field content into a normalized value between 0 and 1
    /// sets the component value to the result, updates the text field content after updating the value
    /// and stores the color to history
    ///
    /// - Note: If parsing the text field content fails, fallback to the previous value.
    func commitColor() {
        isFocused = false
        guard let normalized = inputType.normalize(text) else {
            text = valueString
            return
        }
        setValue(T(value: normalized))
        text = valueString
        storeColor()
    }
    
    /// Blurs the text field and sets the text field content to the current component value.
    private func cancelField() {
        if isFocused {
            text = valueString
            isFocused = false
        }
    }
    
    /// Increases a value by a step adapted to the current ``InputType`` multiplier and clamps it between 0 and 1.
    ///
    /// - Returns: The increased (decreased if `step` is negative) value clamped between 0 and 1.
    ///
    /// - Parameters:
    ///   - value: The target value to be increased.
    ///   - step: The increase amount (can be negative for decreasing).
    private func increaseValue(_ value: CGFloat, by step: CGFloat) -> CGFloat {
        let steppedValue = (value + step / CGFloat(inputType.multiplier))
        if inputType == .degrees {
            let value = steppedValue.truncatingRemainder(dividingBy: 1)
            return value < 0 ? value + 1 : value
        } else {
            return steppedValue.clamped(to: 0...1)
        }
    }
    
    /// Steps the component value if the text field is not focused and steps the text content if the text field is focused.
    private func stepValue(by amount: CGFloat) {
        if isFocused {
            let newValue = increaseValue(inputType.normalize(text) ?? value.cgFloatValue, by: amount)
            text = inputType.format(newValue)
        } else {
            let newValue = increaseValue(getValue().cgFloatValue, by: amount)
            setValue(T(value: newValue))
        }
    }
    
    static func == (a: Self, b: Self) -> Bool { a.value == b.value && a.inputType == b.inputType }
}

/// Displays a component label alongside a ``ColorComponentField``.
struct ColorComponentFieldContainer<Content: View>: View {
    let component: String
    let componentField: Content
    
    init(component: String, @ViewBuilder componentField: () -> Content) {
        self.component = component
        self.componentField = componentField()
    }
    
    var body: some View {
        HStack {
            Text(verbatim: component)
                .lineLimit(1)
                .bold()
                .frame(width: SidebarLayout.componentLabelWidth)
            componentField
        }
    }
}
