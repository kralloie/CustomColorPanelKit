//
//  ColorValuesView.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 23/06/2026.
//

import SwiftUI

struct ColorValuesView: View {
    @Binding var color: HSBAColor
    var colorHistory: ColorHistory
    @State private var contentHeight: CGFloat = 0
    @State private var hoveringEyedropper: Bool = false
    @State private var isOpen: Bool = true
    @State private var isHoveringTogglePanel: Bool = false
    
    var body: some View {
        let rgb = color.rgb
        let cmyk = color.cmyk
        let hsl = color.hsl
        let hex = color.hex
        let storeColor = { colorHistory.add(color) }
        
        ScrollView {
            VStack(spacing: 4) {
                ColorExample(color: color, size: 80)
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
                            .onHover { hoveringEyedropper = $0 }
                            .scaleEffect(hoveringEyedropper ? 1.05 : 1)
                            .animation(.easeInOut(duration: 0.1), value: hoveringEyedropper)
                    }
                    .padding(.bottom, 10)
                
                Divider()
                
                ColorValueLabel(label: "HEX", value: $color.hex, inputType: .hex, storeColor: storeColor)
                
                Divider()
                
                ColorValueLabel(label: "H", value: $color.hue, inputType: .degrees, storeColor: storeColor)
                ColorValueLabel(label: "S", value: $color.saturation, inputType: .percentage, storeColor: storeColor)
                ColorValueLabel(label: "V", value: $color.brightness, inputType: .percentage, storeColor: storeColor)
                
                Divider()
              
                ColorValueLabel(label: "H", value: $color.hsl.hue, inputType: .degrees, storeColor: storeColor)
                ColorValueLabel(label: "S", value: $color.hsl.saturation, inputType: .percentage, storeColor: storeColor)
                ColorValueLabel(label: "L", value: $color.hsl.lightness, inputType: .percentage, storeColor: storeColor)

                Divider()
                
                ColorValueLabel(label: "R", value: $color.rgb.red, inputType: .numerical, storeColor: storeColor)
                ColorValueLabel(label: "G", value: $color.rgb.green, inputType: .numerical, storeColor: storeColor)
                ColorValueLabel(label: "B", value: $color.rgb.blue, inputType: .numerical, storeColor: storeColor)
                
                Divider()
  
                ColorValueLabel(label: "C", value: $color.cmyk.cyan, inputType: .percentage, storeColor: storeColor)
                ColorValueLabel(label: "M", value: $color.cmyk.magenta, inputType: .percentage, storeColor: storeColor)
                ColorValueLabel(label: "Y", value: $color.cmyk.yellow, inputType: .percentage, storeColor: storeColor)
                ColorValueLabel(label: "K", value: $color.cmyk.key, inputType: .percentage, storeColor: storeColor)

                Divider()
                
                ColorValueLabel(label: "Opacity", value: $color.alpha, inputType: .percentage, storeColor: {})
                
                Divider()
                
                ColorHistoryView(color: $color, colorHistory: colorHistory)
            }
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { contentHeight = geo.size.height }
                        .onChange(of: geo.size.height) { contentHeight = geo.size.height }
                }
            }
        }
        .frame(maxHeight: contentHeight == 0 ? .infinity : contentHeight)
        .frame(width: isOpen ? 200 : 0)
        .scrollIndicators(.hidden)
        .clipped()
        .padding(isOpen ? 20 : 0)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        }
        .overlay(alignment: .leading, content: { togglePanelButton })
        .padding(10)
    }
    
    private var togglePanelButton: some View {
        return Image(systemName: isOpen ? "chevron.left" : "chevron.right")
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
            .offset(x: -10)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isOpen.toggle()
                }
            }
            .onHover { isHoveringTogglePanel = $0 }
            .animation(.easeInOut(duration: 0.1), value: isHoveringTogglePanel)
    }
}

private struct ColorValueLabel: View {
    let label: String
    let inputType: InputType
    @Binding var value: String
    @State private var text: String
    let storeColor: () -> Void
    @FocusState private var isFocused: Bool
    @State private var isHovering: Bool = false
    
    init(label: String, value: Binding<CGFloat>, inputType: InputType, storeColor: @escaping () -> Void) {
        let valueStr = String(format: inputType.format, value.wrappedValue * CGFloat(inputType.multiplier))
        self.label = label
        self.inputType = inputType
        self._value = Binding(
            get: { String(format: inputType.format, value.wrappedValue * CGFloat(inputType.multiplier)) },
            set: { value.wrappedValue = inputType.validate($0) }
        )
        self.storeColor = storeColor
        self._text = .init(initialValue: valueStr)
    }
    
    init(label: String, value: Binding<UInt32>, inputType: InputType, storeColor: @escaping () -> Void) {
        let valueStr = String(format: inputType.format, value.wrappedValue)
        self.label = label
        self.inputType = inputType
        self._value = Binding(
            get: { String(format: inputType.format, value.wrappedValue) },
            set: { value.wrappedValue = UInt32(inputType.validate($0)) }
        )
        self.storeColor = storeColor
        self._text = .init(initialValue: valueStr)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
            TextField("", text: $text)
                .monospaced()
                .multilineTextAlignment(.trailing)
                .onKeyPress(keys: [.upArrow, .downArrow]) { press in
                    guard !(inputType == .hex) else { return .handled }
                    guard isFocused else { return .handled }
                    
                    let step: CGFloat = press.key == .upArrow ? 1 : -1
                    var current = inputType.validate(text) * CGFloat(inputType.multiplier)
                    current = inputType.validate(String(format: inputType.format, current + step))
                    let newValueString = String(format: inputType.format, current * CGFloat(inputType.multiplier))
                    text = newValueString
                    
                    return .handled
                }
                .onSubmit {
                    isFocused = false
                    value = text
                    storeColor()
                }
                .onExitCommand {
                    if isFocused {
                        text = value
                        isFocused = false
                    }
                }
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onChange(of: value) { _, newValue in
                    isFocused = false
                    text = newValue
                }
                .onChange(of: isFocused) {_ , focused in
                    if !focused { text = value }
                }
                .onHover { isHovering = $0 }
                .background(
                    ScrollWheelMonitor { _, event in
                        guard !(inputType == .hex) else { return }
                        guard isHovering || isFocused else { return }
                        let step: Double = 1
                        let delta = event.scrollingDeltaY > 0 ? step : -step
                        
                        var current = inputType.validate(text) * CGFloat(inputType.multiplier)
                        current = inputType.validate(String(format: inputType.format, current + delta))
                        let newValueString = String(format: inputType.format, current * CGFloat(inputType.multiplier))
                        
                        if isFocused {
                            text = newValueString
                        } else {
                            value = newValueString
                        }
                    }
                )
                .frame(width: 75)
        }
    }
}

#Preview {
    ColorValuesView(color: .constant(HSBAColor(with: .orange)), colorHistory: ColorHistory())
        .frame(width: 200)
        .padding()
}
