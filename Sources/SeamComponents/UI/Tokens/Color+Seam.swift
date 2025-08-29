// MARK: - Dynamic Color Utilities
import SwiftUI

/// Seam-specific convenience initializers for dynamic colors that adapt to Light and Dark Mode.
///
/// These initializers produce a `Color` that resolves to the provided light or dark variant
/// based on the current `UITraitCollection`. On platforms without appearance differentiation
/// (e.g., watchOS), the dark variant is used.

public extension Color {
    /// Creates a dynamic SwiftUI color from two SwiftUI `Color` values.
    ///
    /// Internally bridges to the `Color/init(light:dark:)` (UIKit) initializer to support
    /// trait-based resolution across appearances.
    ///
    /// - Parameters:
    ///   - light: The color to use in Light Mode (and when the interface style is `.unspecified`).
    ///   - dark: The color to use in Dark Mode.
    ///
    /// - Example:
    /// ```swift
    /// let dynamic = Color(light: .white, dark: .black)
    /// ```
    init(light: Color, dark: Color) {
        self.init(light: UIColor(light), dark: UIColor(dark))
    }

    /// Creates a dynamic SwiftUI color from two `UIColor` values.
    ///
    /// Uses a `UIColor(dynamicProvider:)` to resolve the appropriate variant at render time.
    ///
    /// - Platform behavior:
    ///   - **watchOS**: Uses the `dark` variant because watchOS does not differentiate appearance.
    ///   - **iOS/iPadOS/macCatalyst**: Resolves by `traits.userInterfaceStyle`; falls back to `light` for `.unspecified`.
    ///
    /// - Parameters:
    ///   - light: The color to use in Light Mode (and `.unspecified`).
    ///   - dark: The color to use in Dark Mode.
    init(light: UIColor, dark: UIColor) {
        #if os(watchOS)
        // watchOS does not differentiate Light/Dark appearance; use the `dark` variant.
        self.init(uiColor: dark)
        #else
        self.init(uiColor: UIColor(dynamicProvider: { traits in
            switch traits.userInterfaceStyle {
            case .light, .unspecified:
                return light

            case .dark:
                return dark

            // Future interface styles: assert in debug and fall back to the light variant.
            @unknown default:
                assertionFailure("Unknown userInterfaceStyle: \(traits.userInterfaceStyle)")
                return light
            }
        }))
        #endif
    }
}
