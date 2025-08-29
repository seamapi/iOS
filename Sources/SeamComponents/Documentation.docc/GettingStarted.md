# Getting Started with SeamComponents

SeamComponents is designed to make it easy to integrate digital keys and access management into your iOS app using SwiftUI. Follow this guide to get up and running in minutes.

---

## 1. Add SeamComponents to Your Project

Add SeamComponents using [Swift Package Manager](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app):

1. Open your Xcode project.
2. Go to **File > Add Packages…**
3. Enter the package URL:  
   ```
   https://github.com/seamapi/seam-components-swift
   ```
4. Choose the latest version and add it to your app target.

---

## 2. Initialize Seam SDK

Before you use any SeamComponents UI, you need to initialize the Seam SDK with your provided token.

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

*Tip: Call `initialize` after sign‑in (or app launch) and then `activate()` to begin syncing credentials.*

---

## 3. Use the All-in-One Access View

For the easiest integration, add the main Seam access view directly to your SwiftUI hierarchy:

```swift
import SeamComponents

var body: some View {
    SeamAccessView()
}
```

That’s it! The all-in-one view handles key retrieval, credential display, unlocking, error handling, and user interactions—no extra setup needed.

---

## 4. Customizing Appearance (Theming)

SeamComponents makes it easy to match your app's look and feel by supporting full theming via the `SeamTheme` environment value. Override any colors or fonts globally by applying your custom theme:

```swift
// Start from the default theme, then override specific roles.
let myTheme = SeamTheme.default
    .with(colors: .default.with(accent: .orange))
    .with(fonts: .default.with(largeTitle: .system(size: 36, weight: .bold)))

var body: some View {
    SeamAccessView()
        .environment(\.seamTheme, myTheme)
}
```

> **Default behavior:** If you don’t inject a theme, SeamComponents use `SeamTheme.default`.

**Note:** ``SeamTheme`` supports partial overrides using the `.with(...)` method, allowing you to update only specific colors or fonts without redefining the entire theme. Theming can be applied globally or scoped to any view subtree.

```swift
// Partial override: change only the accent color
let pinkAccentTheme = SeamTheme.default
    .with(colors: .default.with(accent: .pink))

var body: some View {
    SeamAccessView()
        .environment(\.seamTheme, pinkAccentTheme)
}
```

All SeamComponents—including credential lists, key card views, buttons, and banners—automatically respect the active theme within the view hierarchy.

See [Customizing Appearance](doc:CustomizingAppearance) for details and more examples.

---

## 5. Custom Integration

If you need more control, compose your own UI using SeamComponents building blocks (key lists, unlock buttons, error banners) and inject a live `SeamService` or a mock conforming to `SeamServiceProtocol` for testing and previews.

See the [Custom Integration](doc:CustomIntegration) article for details and advanced examples.

---

## 6. Need Help?

- [Seam SDK Documentation](https://docs.seam.co/)
- [Support](https://docs.seam.co/support)

---

## More Resources

- [Customizing Appearance](doc:CustomizingAppearance)  
- [SeamComponents Reference Documentation](https://docs.seam.co/seamcomponents)

---

## Further Reading

- [Getting Started](doc:GettingStarted)
- [Customizing Appearance](doc:CustomizingAppearance)
- [Custom Integration](doc:CustomIntegration)

**You’re now ready to get started with SeamComponents. Happy coding!**
