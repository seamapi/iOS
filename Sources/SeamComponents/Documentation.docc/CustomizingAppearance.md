# Customizing Appearance

Customize every aspect of SeamComponents’ appearance—including colors, fonts, and status indicators—using the composable SeamTheme system.

## Overview

SeamComponents provides a flexible theming system that allows you to fully customize the look and feel of all UI elements in the library. This enables easy white-labeling, brand alignment, and accessibility support.

Theming is accomplished by configuring a `SeamTheme` value—which groups together all colors and fonts for the UI—and injecting it into your SwiftUI view hierarchy using the `.environment(\.seamTheme, ...)` modifier.

> **Default behavior:** If you don’t inject a theme, SeamComponents use `SeamTheme.default`.

All SeamComponents (such as ``SeamAccessView``, ``SeamKeyCardView``, ``SeamCredentialsView``, and ``SeamUnlockCardView``) automatically use the current theme for their appearance, so you can apply a consistent look across your app with just one line of code.

---

## Why Theming Matters

Applying a custom theme allows you to:

- **White-label your app** by replacing default colors and fonts with your brand’s identity.
- **Align your UI with your brand guidelines** for a consistent and professional appearance.
- **Support accessibility features** such as Dynamic Type and high-contrast modes, ensuring your app is usable by everyone.

---

## Quick Start

### Basic Custom Theme

```swift
// Start from the default theme and override specific roles.
let myTheme = SeamTheme.default
    .with(colors: .default.with(accent: .orange))
    .with(fonts: .default.with(largeTitle: .system(size: 36, weight: .bold)))

// Apply to your view hierarchy:
SeamAccessView()
    .environment(\.seamTheme, myTheme)
```

### Partial Customization

```swift
// Override only what you need and keep the rest of the defaults:
let partialTheme = SeamTheme.default
    .with(colors: .default.with(accent: .green))
    .with(fonts: .default.with(body: .system(size: 16, weight: .medium)))

SeamAccessView()
    .environment(\.seamTheme, partialTheme)
```

---

## Design Tips

- **Accent drives actions:** The `colors.accent` role powers primary buttons and highlights.
- **Prefer dynamic colors:** Use light/dark‑aware colors so your theme looks great in both appearances.
- **Keep fonts accessible:** Favor Dynamic Type–friendly fonts; avoid locking sizes unless necessary.

---

## Theme Scope and Environment

Themes in SeamComponents can be applied globally or scoped to a portion of your UI:

- **Global Theming:** Apply a theme at the root of your app’s view hierarchy to affect all SeamComponents.
- **Subtree Theming:** Apply a theme to a specific view or container to override the theme only for that subtree.

This flexibility allows you to easily customize appearance for entire apps or specific screens and components.

---

## FAQ

**Q: What happens if I don’t provide a theme?**  
A: All SeamComponents will use the built-in default theme, which matches the native iOS style.

**Q: Can I override only some colors or fonts?**  
A: Yes! SeamTheme is fully composable—provide only the values you want to override; everything else falls back to the default.

**Q: Does theming work with accessibility features?**  
A: Yes. All theme values work seamlessly with Dynamic Type, high-contrast settings, and other accessibility features.

**Q: Can I change the theme at runtime?**  
A: Absolutely. Because theming is driven by SwiftUI’s environment system, updating the theme dynamically will automatically update all affected SeamComponents.

---

## See Also

- [SeamTheme](doc:SeamTheme)  
- [Colors](doc:SeamTheme/Colors)
- [Fonts](doc:SeamTheme/Fonts)
- [Key Card](doc:SeamTheme/KeyCard)
- [Getting Started](doc:GettingStarted)

## Further Reading

- [Seam SDK Documentation](https://docs.seam.co/)
- [Support](https://docs.seam.co/support)
- [Getting Started](doc:GettingStarted)
- [Custom Integration](doc:CustomIntegration)
