//
//  ColorComponentField.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 13/08/2026.
//

import SwiftUI

struct ColorComponentField<T: ColorComponentNumeric>: View {
    @Binding var value: String
    @Binding var valueBinding: T
    var sliderWidth: CGFloat
    
    @State private var text: String
    @State private var isHovering: Bool = false
    @FocusState private var isFocused: Bool
    
    let inputType: InputType
    let storeColor: () -> Void
    
    init(value: Binding<T>, inputType: InputType, storeColor: @escaping () -> Void = {}, sliderWidth: CGFloat = 0) {
        self.inputType = inputType
        self._value = Binding(
            get: { inputType.format(value.wrappedValue.cgFloatValue) },
            set: { value.wrappedValue = T(value: inputType.normalize($0)) }
        )
        self._valueBinding = value
        self.sliderWidth = sliderWidth
        self.storeColor = storeColor
        self._text = .init(initialValue: inputType.format(value.wrappedValue.cgFloatValue))
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if inputType != .hex {
                slider(
                    normalized: Binding(
                        get: {
                            isFocused ? inputType.normalize(text) : valueBinding.cgFloatValue
                        },
                        set: {
                            if isFocused {
                                text = inputType.format($0)
                            } else {
                                valueBinding = T(value: $0)
                            }
                        }
                    ),
                    width: sliderWidth
                )
            }
            
            ZStack(alignment: .leading) {
                TextField("", text: $text)
                    .multilineTextAlignment(.center)
                    .frame(width: inputType == .hex ? 70 : 50, height: 24)
                    .textFieldStyle(.plain)
                    .onKeyPress(keys: [.upArrow, .downArrow], action: handleArrows)
                    .onSubmit(submitText)
                    .onExitCommand(perform: cancelField)
                    .focused($isFocused)
                    .onChange(of: isFocused, updateText)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.background.secondary)
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                    .opacity(isFocused ? 1 : 0)
                
                Text(value)
                    .frame(width: inputType == .hex ? 70 : 50, height: 24)
                    .contentShape(Rectangle())
                    .onTapGesture { isFocused = true }
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.background.secondary)
                            .stroke(.separator, lineWidth: 1)
                    }
                    .opacity(isFocused ? 0 : 1)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering { NSCursor.iBeam.set() } else { NSCursor.arrow.set() }
            }
            .background {
                if inputType != .hex {
                    ScrollWheelMonitor(isHovering: isHovering, storeColor: storeColor, onScroll: handleScroll)
                }
            }
            
            if inputType != .hex { stepper(isFocused: isFocused, storeColor: storeColor, stepValue: stepValue(by:)) }
        }
    }
    
    private struct stepper: View {
        @State var isFocused: Bool
        var storeColor: () -> Void
        var stepValue: (CGFloat) -> Void
        @State private var hoveringChevron: Int? = nil
        
        var body: some View {
            VStack(spacing: 2) {
                Image(systemName: "chevron.up")
                    .background { RoundedRectangle(cornerRadius: 4).fill(hoveringChevron == 1 ? .gray.opacity(0.2) : .clear) }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        stepValue(1)
                        if !isFocused { storeColor() }
                    }
                    .onHover { hoveringChevron = $0 ? 1 : nil }
                
                Image(systemName: "chevron.down")
                    .background { RoundedRectangle(cornerRadius: 4).fill(hoveringChevron == -1 ? .gray.opacity(0.2) : .clear) }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        stepValue(-1)
                        if !isFocused { storeColor() }
                    }
                    .onHover { hoveringChevron = $0 ? -1 : nil }
            }
        }
    }
    
    private struct slider: View {
        @Binding var normalized: CGFloat
        var width: CGFloat
        @State private var isDragging: Bool = false
        
        var body: some View {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: normalized * width)
            }
            .frame(width: width, height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.clear)
                        .frame(width: 17, height: 13)
                        .background {
                            ZStack {
                                if isDragging {
                                    Capsule().glassEffect(.clear, in: Capsule())
                                } else {
                                    Capsule().fill(.white).shadow(radius: 2)
                                }
                            }
                        }
                        .scaleEffect(isDragging ? 1.25 : 1)
                        .animation(.easeInOut(duration: 0.1), value: isDragging)
                        .offset(x: width * normalized - 7.5)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged {
                                    if !isDragging { isDragging = true }
                                    normalized = ($0.location.x / width).clamped(to: 0...1)
                                }
                                .onEnded { _ in isDragging = false }
                        )
                }
                .position(x: width * 0.5, y: 12)
                .gesture(
                    SpatialTapGesture()
                        .onEnded { normalized = ($0.location.x / width).clamped(to: 0...1) }
                )
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
    
    private func updateText() { text = value }
    
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
