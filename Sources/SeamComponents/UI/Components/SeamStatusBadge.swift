import SwiftUI

/// A compact, theme-aware status badge with an icon and text.
///
/// ``SeamStatusBadge`` renders a pill-shaped label that combines an SF Symbol and
/// a short message. The badge color is supplied by the caller and layered behind a
/// material background for legibility. Typography is derived from the current
/// ``SeamTheme`` via the `seamTheme` environment value.
///
/// - Usage:
/// ```swift
/// SeamStatusBadge(
///     iconName: "exclamationmark.circle.fill",
///     text: "Expired",
///     color: SeamTheme.default.colors.danger
/// )
/// ```
///
/// - Important: Choose a `color` that meets contrast guidelines against your
/// app background. The view applies `.thickMaterial` to improve text readability
/// over bright or saturated colors.
public struct SeamStatusBadge: View {
    /// The current theme from the environment. Used for fonts and text color.
    @Environment(\.seamTheme) private var theme
    /// The SF Symbol name displayed at the leading edge of the badge.
    public let iconName: String
    /// The localized label text rendered next to the icon.
    public let text: LocalizedStringKey
    /// The base badge color painted behind the material for emphasis.
    public let color: Color

    /// Creates a new status badge.
    ///
    /// - Parameters:
    ///   - iconName: The SF Symbol name to display.
    ///   - text: A localized string key for the badge label.
    ///   - color: The base background color of the badge.
    public init(iconName: String, text: LocalizedStringKey, color: Color) {
        self.iconName = iconName
        self.text = text
        self.color = color
    }

    /// The badge view.
    ///
    /// Composed of an `HStack` with an icon and text, wrapped in a rounded rectangle
    /// with a material overlay and a solid color background for clarity and contrast.
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundStyle(color)
            Text(text)
        }
        .font(theme.fonts.callout)
        .foregroundColor(theme.colors.primaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thickMaterial)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        SeamStatusBadge(
            iconName: "exclamationmark.circle.fill",
            text: "Expired",
            color: SeamTheme.default.colors.danger
        )
        SeamStatusBadge(
            iconName: "checkmark.circle.fill",
            text: "Unlocked",
            color: SeamTheme.default.colors.info
        )
        SeamStatusBadge(
            iconName: "clock.fill",
            text: "Pending",
            color: SeamTheme.default.colors.warning
        )
    }
    .padding()
    .environment(\.seamTheme, SeamTheme.previewTheme)

    VStack(spacing: 16) {
        SeamStatusBadge(
            iconName: "exclamationmark.circle.fill",
            text: "Expired",
            color: .red
        )
        SeamStatusBadge(
            iconName: "checkmark.circle.fill",
            text: "Unlocked",
            color: .green
        )
        SeamStatusBadge(
            iconName: "clock.fill",
            text: "Pending",
            color: .yellow
        )
    }
    .padding()
    .background(RoundedRectangle(cornerRadius: 8).fill(SeamTheme.default.colors.darkFill))
    .padding()
    .environment(\.seamTheme, SeamTheme.previewTheme)
}
#endif
