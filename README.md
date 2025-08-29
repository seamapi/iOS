readme

# Seam Mobile Components (iOS)

Pre-built SwiftUI views for unlocking, credential handling, error states, and feedback — ready to drop into your iOS app and fully customizable to match your brand.

---

## Features

- 🚀 **Fast integration** — Add complete access flows in minutes with `SeamAccessView`.
- 🎨 **Customizable** — White-label theming via `SeamTheme` (colors, fonts, key cards, toasts, unlock cards).
- ✅ **Production-ready** — Includes error handling, retries, haptics, and feedback out of the box.
- 🔗 **Seam SDK integration** — Works seamlessly with [Seam Mobile SDK](https://docs.seam.co/latest/capability-guides/mobile-access/mobile-device-sdks).
- 🧩 **Composable** — Use all-in-one views or mix with your own UI.

---

## Requirements

- Xcode 15+
- iOS 16+
- Swift Package Manager
- A [Seam workspace](https://docs.seam.co) and API key

---

## Installation

Add **Seam Mobile Components** to your project using **Swift Package Manager**:

```swift
dependencies: [
    .package(url: "https://github.com/seamapi/SeamComponents", from: "1.0.0")
]
```

Then import it:

```swift
import SeamComponents
```

---

## Quick Start

The fastest way to get started is with `SeamAccessView`, which orchestrates all underlying components to deliver a complete unlock experience:

```swift
import SwiftUI
import SeamComponents

struct ContentView: View {
    var body: some View {
        SeamAccessView()
    }
}
```

That’s it — you now have a fully functional unlock UI in your app.

---

## How It Works with Seam Mobile SDK

`SeamAccessView` automatically hooks into the SDK for device discovery, credential management, and unlock flows.

---

## Theming

Seam Mobile Components are fully brandable using `SeamTheme`. Apply your own colors, fonts, and styles globally or locally:

```swift
let customTheme = SeamTheme(
  colors: .default.with(accent: .orange),
  fonts: .default.with(largeTitle: .system(size: 36, weight: .bold)),
  keyCard: .default.with(cornerRadius: 20)
)

SeamAccessView()
  .environment(\.seamTheme, customTheme)
```

Learn more in the [Theming Guide](https://docs.seam.co/latest/ui-components/mobile/theming).

---

## Documentation

- [Overview](https://docs.seam.co/latest/ui-components/mobile/overview)  
- [Getting Started](https://docs.seam.co/latest/ui-components/mobile/getting-started)  
- [Theming](https://docs.seam.co/latest/ui-components/mobile/theming)  
- [Advanced Usage](https://docs.seam.co/latest/ui-components/mobile/advanced)  

---

## License

[MIT](LICENSE)

---

## Contributing

Issues and pull requests are welcome! Please open a GitHub issue for bugs, feature requests, or integration questions.
