// MARK: - Seam Text Styles
import SwiftUI

/// A semantic text style `ViewModifier` backed by the current ``SeamTheme``.
///
/// ``TextStyle`` applies fonts from ``SeamTheme/fonts`` and colors from ``SeamTheme/colors``
/// to `Text` based on the selected ``TextStyle/Style``. Header styles add the appropriate
/// accessibility traits for better VoiceOver navigation.
///
/// ### Usage
/// ```swift
/// Text("Title").textStyle(.title)
/// Text("Caption").textStyle(.caption)
/// ```
///
/// - SeeAlso: `Text/textStyle(_:)`, ``SeamTheme``
public struct TextStyle: ViewModifier {
    /// The active theme providing fonts and colors.
    @Environment(\.seamTheme) private var theme

    /// Semantic text roles mapped to theme fonts and colors.
    ///
    /// Choose a case based on the content’s importance and context. Header cases add
    /// `.isHeader` for improved accessibility.
    public enum Style {
        /// Extra‑large display title; prominent page header.
        case largeTitle
        /// Primary page or section title.
        case title
        /// Secondary title style.
        case title2
        /// Tertiary title style.
        case title3
        /// Emphasized heading for short labels.
        case headline
        /// Subheading used below a primary title.
        case subheadline
        /// Standard body copy.
        case body
        /// Short descriptive callout.
        case callout
        /// Small supporting text in a secondary color.
        case footnote
        /// Small supporting text in a primary color.
        case footnotePrimary
        /// Caption text for annotations; secondary color.
        case caption
        /// Smaller caption variant; secondary color.
        case caption2

        /// Section header label with subtle emphasis; marked as a header for accessibility.
        case sectionHeader
    }

    /// The semantic style to apply.
    private let style: Style

    /// Creates a text style modifier.
    /// - Parameter style: The semantic style to apply.
    public init(style: Style) {
        self.style = style
    }

    /// Applies the theme’s font and color for the selected style.
    ///
    /// - Behavior:
    ///   - All styles align text to `.leading`.
    ///   - Header styles (`.largeTitle`, `.title*`, `.sectionHeader`) add `.isHeader` traits.
    ///   - Secondary text color is used for `.footnote`, `.caption`, and `.caption2`.
    @ViewBuilder public func body(content: Content) -> some View {
        switch style {
        case .largeTitle:
            content
                .font(theme.fonts.largeTitle)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)

        case .title:
            content
                .font(theme.fonts.title)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)

        case .title2:
            content
                .font(theme.fonts.title2)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)

        case .title3:
            content
                .font(theme.fonts.title3)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)

        case .headline:
            content
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)

        case .subheadline:
            content
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)

        case .body:
            content
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)

        case .callout:
            content
                .font(theme.fonts.callout)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)

        case .footnote:
            content
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryText)
                .multilineTextAlignment(.leading)

        case .footnotePrimary:
            content
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.leading)

        case .caption:
            content
                .font(theme.fonts.caption)
                .foregroundColor(theme.colors.secondaryText)
                .multilineTextAlignment(.leading)

        case .caption2:
            content
                .font(theme.fonts.caption2)
                .foregroundColor(theme.colors.secondaryText)
                .multilineTextAlignment(.leading)

        case .sectionHeader:
            content
                .font(theme.fonts.sectionHeader)
                .foregroundColor(theme.colors.secondaryText)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

public extension Text {
    /// Applies a semantic ``TextStyle`` using the current ``SeamTheme``.
    ///
    /// - Parameter style: The semantic text style to apply.
    /// - Returns: A `View` with the appropriate font, color, and accessibility traits.
    ///
    /// ### Example
    /// ```swift
    /// Text("The quick brown fox").textStyle(.body)
    /// ```
    ///
    /// - Important: This modifier runs on the main actor.
    @MainActor func textStyle(_ style: TextStyle.Style) -> some View {
        self.modifier(TextStyle(style: style))
    }
}


#if DEBUG
/// Demonstrates each semantic text style using the preview theme.
#Preview {
    let textStyles = [
        ("largeTitle", TextStyle.Style.largeTitle),
        ("title", TextStyle.Style.title),
        ("title2", TextStyle.Style.title2),
        ("title3", TextStyle.Style.title3),
        ("headline", TextStyle.Style.headline),
        ("subheadline", TextStyle.Style.subheadline),
        ("body", TextStyle.Style.body),
        ("callout", TextStyle.Style.callout),
        ("footnote", TextStyle.Style.footnote),
        ("footnotePrimary", TextStyle.Style.footnotePrimary),
        ("caption", TextStyle.Style.caption),
        ("caption2", TextStyle.Style.caption2),
        ("sectionHeader", TextStyle.Style.sectionHeader)
    ]

    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(textStyles, id: \.0) { name, style in
                VStack {
                    HStack {
                        Text(name)
                            .font(SeamTheme.default.fonts.body)
                        Spacer()
                    }
                    Text("The quick brown fox")
                        .textStyle(style)
                        .frame(maxWidth: .infinity)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .environment(\.seamTheme, SeamTheme.previewTheme)
}
#endif
