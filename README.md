# CustomColorPanelKit 🎨
A color-picking panel for macOS, built with SwiftUI and Metal. It combines GPU-rendered color pickers with precise component controls in a native macOS interface.

<img width="1896" height="1165" alt="image" src="https://github.com/user-attachments/assets/7cd9a9f4-d7f4-4ce2-9efc-8a9d5c7e26a4" />
<img width="1896" height="1165" alt="image" src="https://github.com/user-attachments/assets/2786ff37-7686-4ca6-95e4-47dbd6150ec6" />
<img width="1896" height="1165" alt="image" src="https://github.com/user-attachments/assets/2d60cd47-9972-4663-9dfe-072919c9ff16" />

## Features:

  ### Three color pickers
  - Hue Ring — Select hue around a ring, then adjust saturation and brightness using the triangle inside it.
  - HSV Square — Adjust saturation and brightness in a square, with a separate hue slider.
  - Hue Sphere — Select hue by angle and saturation by distance from the center, with a separate brightness slider.
  Each picker includes an opacity slider.

  ### Color controls
  - Editable HEX, HSV, HSL, RGB, and CMYK values, plus alpha.
  - Sliders, text fields, and steppers for individual color components.
  - On-screen color preview with an opacity checkerboard.
  - Copy color values in HEX, HSV, HSL, RGB, or CMYK format.
  - Eyedropper for sampling a color from the screen.
  - Random color generator and six preset palettes: System, Classic, Pastel, Neon, Warm, and Cool.
  - Session-based color history holding up to 144 colors.
  - Localized interface strings for 13 languages.

## Installation
1. In Xcode, open your macOS app project.
2. Select File → Add Package Dependencies….
3. Enter the GitHub repository URL for CustomColorPanelKit.
4. Select a compatible package version and add CustomColorPanelKit to your app target.

The package has no third-party Swift Package dependencies.

## Usage

Import CustomColorPanelKit and provide a binding to a SwiftUI Color:

```swift
import SwiftUI
import CustomColorPanelKit

struct ContentView: View {
    @State private var selectedColor: Color = .blue

    var body: some View {
        ColorPanelView($selectedColor)
    }
}
```

Changes made in the panel update `selectedColor`. Changes to the bound color from elsewhere in your app are also reflected in the panel.
`ColorPanelView` is the package's public entry point. The picker modes and component controls are managed internally.

## Requirements 
- macOS 26 or later
- Xcode with Swift 6.2 support
