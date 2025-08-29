// MARK: - Seam Button Styles
import SwiftUI

/// Semantic button style variants used across the app.
///
/// Use with SwiftUI's `View/buttonStyle(_:)` by selecting one of the provided style types
/// (e.g., ``SeamPrimaryButtonStyle``, ``SeamSecondaryButtonStyle``) based on the semantic value.
///
/// - Cases:
///   - ``primary``: High‑emphasis action buttons.
///   - ``secondary``: Medium‑emphasis, outlined buttons.
///   - ``tertiary``: Text‑only buttons without background or border.
///   - ``destructive``: High‑emphasis destructive actions, typically shown in red.
public enum SeamButtonType {
    /// High‑emphasis action.
    case primary
    /// Medium‑emphasis, outlined action.
    case secondary
    /// Text‑only action with no background or border.
    case tertiary
    /// Destructive action, emphasizes caution.
    case destructive
}

// MARK: - Primary Button Style

/// A filled, accent‑colored primary button style.
///
/// Applies theme fonts, a full‑width layout, and pressed‑state feedback using opacity and scale.
///
/// - Example:
/// ```swift
/// Button("Save") {}
///   .buttonStyle(SeamPrimaryButtonStyle())
/// ```
public struct SeamPrimaryButtonStyle: ButtonStyle {
    /// Current theme from the environment used for fonts and colors.
    @Environment(\.seamTheme) private var theme

    /// Creates the primary style.
    public init() {}

    /// Builds the styled button label.
    ///
    /// - Parameter configuration: The system‑provided configuration.
    /// - Returns: A view that reflects pressed state and fills available width.
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.fonts.actionTitle)
            .foregroundColor(theme.colors.primaryTextLight)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(
                theme.colors.accent
                    .cornerRadius(8)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0) // Light feedback for accessibility
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Secondary Button Style

/// An outlined secondary button style using the theme accent color.
///
/// Provides medium emphasis with a stroked rounded rectangle and pressed‑state feedback.
///
/// - Example:
/// ```swift
/// Button("Cancel") {}
///   .buttonStyle(SeamSecondaryButtonStyle())
/// ```
public struct SeamSecondaryButtonStyle: ButtonStyle {
    /// Current theme from the environment used for fonts and colors.
    @Environment(\.seamTheme) private var theme

    /// Creates the secondary style.
    public init() {}

    /// Builds the styled button label with an outline.
    /// - Parameter configuration: The system‑provided configuration.
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.fonts.actionTitle)
            .foregroundColor(theme.colors.accent)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.colors.accent, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Tertiary Button Style

/// A plain, text‑only button style without background or border.
///
/// - Example:
/// ```swift
/// Button("Learn More") {}
///   .buttonStyle(SeamTertiaryButtonStyle())
/// ```
public struct SeamTertiaryButtonStyle: ButtonStyle {
    /// Current theme from the environment used for fonts and colors.
    @Environment(\.seamTheme) private var theme

    /// Creates the tertiary style.
    public init() {}

    /// Builds the text‑only styled label.
    /// - Parameter configuration: The system‑provided configuration.
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.fonts.actionTitle)
            .foregroundColor(theme.colors.accent)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Icon Button Style

/// An outlined button style with a leading SF Symbol icon.
///
/// Uses a rounded rectangle stroke and theme‑driven typography and colors.
///
/// - Example:
/// ```swift
/// Button("Archive") { }
///   .buttonStyle(SeamIconButtonStyle(iconName: "archivebox"))
/// ```
public struct SeamIconButtonStyle: ButtonStyle {
    /// Current theme from the environment used for fonts and colors.
    @Environment(\.seamTheme) private var theme

    /// The SF Symbol name rendered before the label.
    private let iconName: String

    /// Creates an icon button style.
    /// - Parameter iconName: The SF Symbol name to display.
    public init(iconName: String) {
        self.iconName = iconName
    }

    /// Builds the styled button label with a leading icon and outline.
    /// - Parameter configuration: The system‑provided configuration.
    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
            configuration.label
        }
        .font(theme.fonts.actionTitle)
        .foregroundColor(theme.colors.primaryText)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.colors.grayFill, lineWidth: 2)
        )
        .opacity(configuration.isPressed ? 0.7 : 1.0)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Destructive Button Style

/// A filled destructive button style in the theme's danger color.
///
/// - Example:
/// ```swift
/// Button("Delete") {}
///   .buttonStyle(SeamDestructiveButtonStyle())
/// ```
public struct SeamDestructiveButtonStyle: ButtonStyle {
    /// Current theme from the environment used for fonts and colors.
    @Environment(\.seamTheme) private var theme

    /// Creates the destructive style.
    public init() {}

    /// Builds the styled destructive label.
    /// - Parameter configuration: The system‑provided configuration.
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.fonts.actionTitle)
            .foregroundColor(theme.colors.primaryText)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(
                theme.colors.danger
                    .cornerRadius(8)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews
#if DEBUG
/// Demonstrates each button style with the preview theme.
///
/// - Note: The preview sets the environment theme to ``SeamTheme/previewTheme``
///   for consistent typography and colors.
#Preview {
    VStack(spacing: 24) {
        Button("Primary Button") {}
            .buttonStyle(SeamPrimaryButtonStyle())
        Button("Secondary Button") {}
            .buttonStyle(SeamSecondaryButtonStyle())
        Button("Tertiary Button") {}
            .buttonStyle(SeamTertiaryButtonStyle())
        Button("Icon Button") {}
            .buttonStyle(SeamIconButtonStyle(iconName: "archivebox"))
        Button("Destructive Button") {}
            .buttonStyle(SeamDestructiveButtonStyle())
    }
    .padding()
    .environment(\.seamTheme, SeamTheme.previewTheme)
}
#endif
