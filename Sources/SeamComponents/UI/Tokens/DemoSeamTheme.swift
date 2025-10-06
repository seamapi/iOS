// Demo themes showcasing SeamTheme customization.
// This file defines a playful high‑contrast theme to demonstrate all SeamTheme roles.

// MARK: - Demo Seam Theme
import SwiftUI

fileprivate extension Color {
    // Light and Dark mode variants for neonRed
    static let neonRedLight = Color(red: 1, green: 0.09, blue: 0.36)      // #FF175B
    static let neonRedDark = Color(red: 0.8, green: 0.05, blue: 0.25)     // darker neon red for dark mode
    static let neonRed = Color(light: neonRedLight, dark: neonRedDark)

    // Light and Dark mode variants for neonBlue
    static let neonBlueLight = Color(red: 0.12, green: 0.85, blue: 1.0)    // #1EEAFF
    static let neonBlueDark = Color(red: 0.05, green: 0.6, blue: 0.8)      // darker neon blue for dark mode
    static let neonBlue = Color(light: neonBlueLight, dark: neonBlueDark)

    // Light and Dark mode variants for neonPink
    static let neonPinkLight = Color(red: 0.98, green: 0.12, blue: 0.86)   // #FA1FDB
    static let neonPinkDark = Color(red: 0.85, green: 0.05, blue: 0.7)     // darker neon pink for dark mode
    static let neonPink = Color(light: neonPinkLight, dark: neonPinkDark)

    // Light and Dark mode variants for neonYellow
    static let neonYellowLight = Color(red: 1.0, green: 0.94, blue: 0.18)  // #FFF02D
    static let neonYellowDark = Color(red: 0.8, green: 0.75, blue: 0.15)   // darker neon yellow for dark mode
    static let neonYellow = Color(light: neonYellowLight, dark: neonYellowDark)

    // Light and Dark mode variants for neonBackground
    static let neonBackgroundLight = Color(red: 14/255, green: 14/255, blue: 24/255) // deep black-blue
    static let neonBackgroundDark = Color(red: 10/255, green: 10/255, blue: 18/255)  // even deeper black-blue
    static let neonBackground = Color(light: neonBackgroundLight, dark: neonBackgroundDark)

    // Light and Dark mode variants for neonSurface
    static let neonSurfaceLight = Color(red: 34/255, green: 34/255, blue: 44/255)    // slightly lighter
    static let neonSurfaceDark = Color(red: 24/255, green: 24/255, blue: 34/255)     // slightly darker surface
    static let neonSurface = Color(light: neonSurfaceLight, dark: neonSurfaceDark)

    // Light and Dark mode variants for neonDarkBlue
    static let neonDarkBlueLight = Color(red: 0.035, green: 0.176, blue: 0.361)
    static let neonDarkBlueDark = Color(red: 0.02, green: 0.1, blue: 0.2)
    static let neonDarkBlue = Color(light: neonDarkBlueLight, dark: neonDarkBlueDark)

    // Dual mode color for dyColor (already defined as light: neonDarkBlue, dark: neonBlue)
    static let dyColor = Color(light: neonDarkBlue, dark: neonBlue)

    // MARK: Brand palette (subtle, high-contrast)
    static let teError   = Color(red: 0.7529, green: 0.1490, blue: 0.1725) // #c0262c
    static let teSuccess = Color(red: 0.0000, green: 0.4078, blue: 0.2157) // #006837

    static let teBlack   = Color(red: 0.0588, green: 0.0549, blue: 0.0706) // #0f0e12
    static let teBlue    = Color(red: 0.0000, green: 0.4431, blue: 0.7333) // #0071bb
    static let teGreen   = Color(red: 0.0000, green: 0.4078, blue: 0.2157) // #006837
    static let teGrey100 = Color(red: 0.8980, green: 0.8980, blue: 0.8980) // #e5e5e5
    static let teGrey200 = Color(red: 0.8000, green: 0.8000, blue: 0.8000) // #cccccc
    static let teGrey900 = Color(red: 0.3020, green: 0.3020, blue: 0.3020) // #4d4d4d
    static let teGrey1000 = Color(red: 0.1529, green: 0.1529, blue: 0.1529) // #272727
    static let teOrange  = Color(red: 0.9412, green: 0.3529, blue: 0.1412) // #f05a24
    static let teRed     = Color(red: 0.7216, green: 0.1137, blue: 0.0745) // #b81d13
    static let teWhite   = Color(red: 0.9608, green: 0.9608, blue: 0.9608) // #f5f5f5
    static let teYellow  = Color(red: 0.9804, green: 0.7059, blue: 0.0745) // #fab413
}

enum DemoSeamTheme {
    /// A playful, high‑contrast demo theme.
    /// Demonstrates all color roles, extended font roles, and key card styling.
    static let theme = SeamTheme(
        colors: .default.with(
            accent: .teOrange,
            primaryText: .teBlack,
            secondaryText: .teGrey900,
            primaryTextLight: .teWhite,
            primaryTextDark: .teBlack,
            danger: .teRed,
            error: .teError,
            warning: .teYellow,
            info: .teBlue,
            success: .teSuccess,
            grayFill: .teGrey200,
            lightFill: .teWhite,
            darkFill: .teBlack,
            secondaryFill: .teGrey200,
            progress: .teBlue,
            secondaryBackground: .teGrey100
        ),
        fonts: .default.with(
            largeTitle: .system(size: 34, weight: .semibold, design: .rounded),
            title: .system(size: 28, weight: .semibold, design: .rounded),
            title2: .system(size: 22, weight: .semibold, design: .rounded),
            title3: .system(size: 20, weight: .medium, design: .rounded),
            headline: .system(size: 17, weight: .semibold, design: .rounded),
            subheadline: .system(size: 15, weight: .medium, design: .rounded),
            body: .system(size: 17, weight: .regular, design: .rounded),
            callout: .system(size: 16, weight: .regular, design: .rounded),
            footnote: .system(size: 13, weight: .regular, design: .rounded),
            caption: .system(size: 12, weight: .regular, design: .rounded),
            caption2: .system(size: 11, weight: .medium, design: .rounded),
            actionTitle: .system(size: 18, weight: .semibold, design: .rounded),
            sectionHeader: .system(size: 13, weight: .semibold, design: .rounded)
        ),
        keyCard: .default.with(
            backgroundGradient: [
                .teWhite,
                .teGrey200
            ],
            accentColor: .teOrange,
            logoAssetName: "SeamLogo",
            cornerRadius: 12,
            shadowColor: .teBlack.opacity(0.25),
            shadowRadius: 8,
            shadowYOffset: 3
        )
    )
}
