# ``SeamComponents``

SeamComponents is a themeable SwiftUI library for mobile access, offering out-of-the-box all-in-one experiences and fully composable, customizable views for use with the Seam SDK.

## Overview

With SeamComponents, you can:

- Add fully-featured mobile key flows to your app with two lines of code.
- Display and manage user credentials (room keys, access cards, more).
- Show credential status, errors, and helpful UI for resolving issues.
- Compose, extend, and theme views for custom user experiences.
  - Theme all components using the `SeamTheme` system for seamless white-labeling.
- Support previews, tests, and the production Seam SDK using a protocol-based service (``SeamServiceProtocol``).
- Enjoy accessibility as a first-class feature throughout all components.

SeamComponents is designed to work hand-in-hand with [Seam SDK](https://docs.seam.co/) and is ideal for hotels, multi-family, or any app integrating digital access.

## When to Use

- **Rapid Onboarding:** Use the all-in-one view for quick, production-ready access flows.
- **Custom UI:** Compose your own experience using our building blocks and a protocol-based service (`SeamServiceProtocol`).

## Prerequisites

- iOS 16+ (Swift 5.5+)
- Add to your Info.plist:
  - `NSBluetoothAlwaysUsageDescription`
- Nice to have (optional): request the `com.apple.developer.passkit.pass-presentation-suppression` entitlement to prevent Apple Wallet from appearing during BLE/NFC scans.

## Quick Start

1. **Add SeamComponents via Swift Package Manager**
2. **Initialize the Seam SDK**
   ```swift
   import SeamSDK

   // Initialize and activate the Seam SDK
   do {
       try Seam.initialize(clientSessionToken: "YOUR_TOKEN")
       Task { try await Seam.shared.activate() }
   } catch {
       // Handle initialization/activation errors (e.g., show an alert)
   }
   ```
3. **Add the all-in-one access view to your UI**
   ```swift
   import SeamComponents

   var body: some View {
       SeamAccessView()
   }
   ```

> **Tip:** You can theme all SeamComponents by injecting your own `SeamTheme` into the environment—see below for an example.


## Theming and Appearance

SeamComponents supports flexible theming and white-labeling via the ``SeamTheme`` system. By injecting a custom `SeamTheme` into the SwiftUI environment, you can override colors, fonts, spacing, and other appearance values globally or partially—making it easy to match your brand or accessibility needs.

> **Default behavior:** If you don’t inject a theme, SeamComponents use `SeamTheme.default`.

The ``SeamTheme`` API uses a builder pattern with nested theme structs that can be overridden selectively using `.with(...)`. This allows you to customize specific parts of the theme (like colors, fonts, or key card appearance) without redefining the entire theme.

```swift
import SeamComponents

let customTheme = SeamTheme.default.with(
    keyCard: .default.with(
        backgroundGradient: [Color.white, Color.blue],
        accentColor: .blue,
        cornerRadius: 16
    ),
    fonts: .default.with(
        title: .system(size: 22, weight: .bold)
    )
)

var body: some View {
    SeamAccessView()
        .environment(\.seamTheme, customTheme)
}
```

For more details and advanced examples, see [Customizing Appearance](doc:CustomizingAppearance).

## Custom Integration

- Use our composable building blocks—``SeamCredentialsView``, ``SeamKeyCardView``, and ``SeamUnlockCardView``—to create fully custom experiences that fit your app's flows.
- SeamComponents uses a protocol-based service (``SeamServiceProtocol``), making it easy to preview, mock, or substitute different data sources for testing and development. The service publishes `credentials` and `isActive`, with Combine publishers for fine‑grained updates.
- Inject a live ``SeamService`` or a mock that conforms to ``SeamServiceProtocol`` for previews and tests.
- See the [Custom Integration](doc:CustomIntegration) article for details and code samples.

## Support and Resources

- [Seam SDK Documentation](https://docs.seam.co/)
- [Support](https://docs.seam.co/support)
