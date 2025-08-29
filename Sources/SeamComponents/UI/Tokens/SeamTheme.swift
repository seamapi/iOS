import SwiftUI

// MARK: - Seam Theme

/// # SeamTheme
///
/// A semantic palette for all SeamComponents, grouping all customizable styling—`colors`, `fonts`, `keyCard`, `toast`, and `unlockCard`—to enable global or local white-labeling, brand customization, and accessibility.
///
/// By injecting your own theme into the SwiftUI environment, you can instantly adapt all Seam UI to your app's style, with no changes required to the views themselves.
///
/// - Important: All SeamComponents (such as ``SeamAccessView``, ``SeamKeyCardView``, ``SeamCredentialsView``, and ``SeamUnlockCardView``) automatically read from the current theme in the environment, so your appearance updates apply everywhere.
///
/// ## Partial Customization
/// `SeamTheme` and its nested palettes (``Colors``, ``Fonts``, ``KeyCard``, ``Toast``, and ``UnlockCard``) support convenient partial overrides using their `with(...)` builder methods. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default.
///
/// For example, to change only the accent color and large title font:
/// ```swift
/// let theme = SeamTheme(
///   colors: .default.with(accent: .orange),
///   fonts: .default.with(largeTitle: .system(size: 36, weight: .bold))
/// )
/// ```
/// This approach avoids verbose duplication and makes it easy to adapt your app's look incrementally.
///
/// ## Usage Example
/// ```swift
/// let customTheme = SeamTheme(
///   colors: .default.with(accent: .orange, error: .pink),
///   fonts: .default.with(largeTitle: .system(size: 36, weight: .bold))
/// )
///
/// SeamAccessView()
///   .environment(\.seamTheme, customTheme)
/// ```
///
/// ## Default Theme
/// If you do not set a theme, SeamComponents use a default system style that matches iOS look and feel.
///
/// ## Theming Scope
/// You can set a theme for your entire app, or override it in just a portion of your view hierarchy.
///
/// ## See Also
/// - ``SeamTheme/Colors``
/// - ``SeamTheme/Fonts``
/// - ``SeamTheme/KeyCard``
/// - ``SeamTheme/Toast``
/// - ``SeamTheme/UnlockCard``
/// - [Customizing Appearance](doc:CustomizingAppearance)
///
/// See nested types for more details on customizing `colors`, `fonts`, `keyCard`, `toast`, and `unlockCard`. See the `with` builder methods for partial customization.
public struct SeamTheme: Sendable, Equatable {
    /// # KeyCard
    ///
    /// A semantic palette for key card UI elements in SeamComponents, including background gradient, accent color, logo, corner radius, and shadow.
    ///
    /// Use this struct to customize the appearance of key cards to match your brand or app style.
    ///
    /// ### Example
    /// ```
    /// let customKeyCard = SeamTheme.KeyCard(
    ///     backgroundGradient: [.blue, .purple],
    ///     accentColor: .white,
    ///     logoAssetName: "my-logo",
    ///     cornerRadius: 18,
    ///     shadowColor: .black.opacity(0.12),
    ///     shadowRadius: 12,
    ///     shadowYOffset: 6
    /// )
    /// ```
    ///
    /// See the `with` builder method for easy partial customization.
    public struct KeyCard: Sendable, Equatable {
        /// The background gradient *colors* for the key card (top-to-bottom order).
        public var backgroundGradient: [Color]
        /// The accent color used for highlights or overlays.
        public var accentColor: Color
        /// The asset name for the logo to display on the card.
        public var logoAssetName: String
        /// The corner radius for the card shape.
        public var cornerRadius: CGFloat
        /// The shadow color for the card.
        public var shadowColor: Color
        /// The shadow blur radius.
        public var shadowRadius: CGFloat
        /// The vertical offset for the shadow.
        public var shadowYOffset: CGFloat

        /**
         Creates a custom key card style for SeamComponents.
         Use this initializer to override any or all appearance properties of the key card.
         - Parameters:
         - backgroundGradient: The background gradient for the card.
         - accentColor: The accent color for card highlights.
         - logoAssetName: The asset name for the logo image.
         - cornerRadius: The corner radius for the card shape.
         - shadowColor: The color of the card's shadow.
         - shadowRadius: The blur radius for the shadow.
         - shadowYOffset: The vertical offset for the shadow.
         */
        public init(
            backgroundGradient: [Color],
            accentColor: Color,
            logoAssetName: String,
            cornerRadius: CGFloat,
            shadowColor: Color,
            shadowRadius: CGFloat,
            shadowYOffset: CGFloat
        ) {
            self.backgroundGradient = backgroundGradient
            self.accentColor = accentColor
            self.logoAssetName = logoAssetName
            self.cornerRadius = cornerRadius
            self.shadowColor = shadowColor
            self.shadowRadius = shadowRadius
            self.shadowYOffset = shadowYOffset
        }

        /// Default key card style matching iOS look and feel.
        public static let `default` = KeyCard(
            backgroundGradient: [.gray.opacity(0.3), .gray.opacity(0.5)],
            accentColor: .accentColor,
            logoAssetName: "SeamLogo",
            cornerRadius: 16,
            shadowColor: .black.opacity(0.10),
            shadowRadius: 10,
            shadowYOffset: 4
        )

        /**
         Returns a copy of this key card style, overriding only the specified values.

         This builder enables partial customization—set only the key card properties you want to override, and all other values are inherited from the original. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default.

         ### Example
         ```swift
         let customKeyCard = SeamTheme.KeyCard.default.with(cornerRadius: 20)
         ```
         - Parameters:
         - backgroundGradient: The background gradient for the card (optional).
         - accentColor: The accent color for highlights (optional).
         - logoAssetName: The asset name for the logo image (optional).
         - cornerRadius: The card's corner radius (optional).
         - shadowColor: The card's shadow color (optional).
         - shadowRadius: The blur radius for the shadow (optional).
         - shadowYOffset: The shadow's vertical offset (optional).
         - Returns: A new `KeyCard` instance with selected values replaced.
         */
        public func with(
            backgroundGradient: [Color]? = nil,
            accentColor: Color? = nil,
            logoAssetName: String? = nil,
            cornerRadius: CGFloat? = nil,
            shadowColor: Color? = nil,
            shadowRadius: CGFloat? = nil,
            shadowYOffset: CGFloat? = nil
        ) -> Self {
            .init(
                backgroundGradient: backgroundGradient ?? self.backgroundGradient,
                accentColor: accentColor ?? self.accentColor,
                logoAssetName: logoAssetName ?? self.logoAssetName,
                cornerRadius: cornerRadius ?? self.cornerRadius,
                shadowColor: shadowColor ?? self.shadowColor,
                shadowRadius: shadowRadius ?? self.shadowRadius,
                shadowYOffset: shadowYOffset ?? self.shadowYOffset
            )
        }
        // See also: Use the `with` builder for partial customization.
    }

    /// # Toast
    ///
    /// Semantic palette for toast banners shown by SeamComponents: background, text, accent, border, corner radius, and shadow.
    /// Use the `with(...)` builder for partial overrides.
    public struct Toast: Sendable, Equatable {
        public var background: Color
        public var textColor: Color
        public var accentColor: Color
        public var borderColor: Color
        public var cornerRadius: CGFloat
        public var shadowColor: Color
        public var shadowRadius: CGFloat
        public var shadowYOffset: CGFloat
        public var horizontalPadding: CGFloat
        public var verticalPadding: CGFloat

        /**
         Creates a custom toast style for SeamComponents.

         Use this initializer to override any or all appearance properties of the toast banner.

         - Parameters:
           - background: Background fill color of the toast container.
           - textColor: Color used for primary text inside the toast.
           - accentColor: Accent color used for icons or highlights in the toast.
           - borderColor: Stroke color used for the toast border.
           - cornerRadius: Corner radius applied to the toast container.
           - shadowColor: Color of the toast shadow.
           - shadowRadius: Blur radius of the toast shadow.
           - shadowYOffset: Vertical offset of the toast shadow.
           - horizontalPadding: Horizontal content padding inside the toast.
           - verticalPadding: Vertical content padding inside the toast.
         */
        public init(
            background: Color,
            textColor: Color,
            accentColor: Color,
            borderColor: Color,
            cornerRadius: CGFloat,
            shadowColor: Color,
            shadowRadius: CGFloat,
            shadowYOffset: CGFloat,
            horizontalPadding: CGFloat,
            verticalPadding: CGFloat
        ) {
            self.background = background
            self.textColor = textColor
            self.accentColor = accentColor
            self.borderColor = borderColor
            self.cornerRadius = cornerRadius
            self.shadowColor = shadowColor
            self.shadowRadius = shadowRadius
            self.shadowYOffset = shadowYOffset
            self.horizontalPadding = horizontalPadding
            self.verticalPadding = verticalPadding
        }

        /// Default toast style matching iOS look and feel.
        public static let `default` = Toast(
            background: Color(UIColor.secondarySystemBackground),
            textColor: .primary,
            accentColor: .accentColor,
            borderColor: Color(UIColor.separator),
            cornerRadius: 14,
            shadowColor: .black.opacity(0.12),
            shadowRadius: 10,
            shadowYOffset: 6,
            horizontalPadding: 14,
            verticalPadding: 10
        )

        /// Returns a copy overriding only specified values.
        public func with(
            background: Color? = nil,
            textColor: Color? = nil,
            accentColor: Color? = nil,
            borderColor: Color? = nil,
            cornerRadius: CGFloat? = nil,
            shadowColor: Color? = nil,
            shadowRadius: CGFloat? = nil,
            shadowYOffset: CGFloat? = nil,
            horizontalPadding: CGFloat? = nil,
            verticalPadding: CGFloat? = nil
        ) -> Self {
            .init(
                background: background ?? self.background,
                textColor: textColor ?? self.textColor,
                accentColor: accentColor ?? self.accentColor,
                borderColor: borderColor ?? self.borderColor,
                cornerRadius: cornerRadius ?? self.cornerRadius,
                shadowColor: shadowColor ?? self.shadowColor,
                shadowRadius: shadowRadius ?? self.shadowRadius,
                shadowYOffset: shadowYOffset ?? self.shadowYOffset,
                horizontalPadding: horizontalPadding ?? self.horizontalPadding,
                verticalPadding: verticalPadding ?? self.verticalPadding
            )
        }
    }

    /// # UnlockCard
    ///
    /// A semantic palette for `SeamUnlockCardView` and related UI elements.
    /// Controls container/header styling, primary key button appearance, progress, instructions, and status colors.
    public struct UnlockCard: Sendable, Equatable {
        // Container & header
        /// Background color for the unlock card container.
        public var cardBackground: Color?
        /// Background color for the header section of the unlock card.
        public var headerBackground: Color?
        /// Divider line color used between header and content.
        public var dividerColor: Color
        /// Text color for the main header title.
        public var headerTitleColor: Color
        /// Text color for the header subtitle.
        public var headerSubtitleColor: Color
        /// Tint color applied to the provider logo.
        public var providerLogoTint: Color
        // Primary action (big key)
        /// Key icon color when idle (before user interaction).
        public var keyIconColorIdle: Color
        /// Key icon color while actively unlocking.
        public var keyIconColorActive: Color
        /// Gradient colors for the large key button background (top-to-bottom order).
        public var keyButtonGradient: [Color]
        /// The shadow color that the Key Button casts.
        public var keyButtonShadowColor: Color
        /// The shadow blur radius that the Key Button casts.
        public var keyButtonShadowRadius: CGFloat
        /// The vertical offset for the shadow that the Key Button casts.
        public var keyButtonShadowYOffset: CGFloat

        // Progress & labels
        /// Color of the progress indicator shown during unlock.
        public var progressColor: Color
        /// Color of the phase (step) title text.
        public var phaseTitleColor: Color
        // Instructions
        /// Color used for instructional text beneath the header.
        public var instructionTextColor: Color
        /// Background color for bullet markers in instructional lists.
        public var bulletBackground: Color
        /// Text color for bullet markers in instructional lists.
        public var bulletTextColor: Color
        // Status views
        /// Color used to indicate a successful unlock state.
        public var successColor: Color
        /// Color used to indicate an error state.
        public var errorColor: Color
        /// Text color for status messages displayed in the card.
        public var statusMessageColor: Color

        /**
         Creates a custom unlock card style for `SeamUnlockCardView` and related UI.

         Use this to control container/header styling, key button appearance, progress, instructions, and status colors.

         - Parameters:
           - cardBackground: Background color for the unlock card container.
           - headerBackground: Background color for the header section.
           - dividerColor: Divider line color between header and content.
           - headerTitleColor: Text color for the header title.
           - headerSubtitleColor: Text color for the header subtitle.
           - providerLogoTint: Tint color applied to the provider logo.
           - keyIconColorIdle: Key icon color when idle.
           - keyIconColorActive: Key icon color while unlocking.
           - keyButtonGradient: Gradient colors for the large key button background.
           - keyButtonShadowColor: Shadow color cast by the key button.
           - keyButtonShadowRadius: Shadow blur radius for the key button.
           - keyButtonShadowYOffset: Vertical shadow offset for the key button.
           - progressColor: Color for the unlock progress indicator.
           - phaseTitleColor: Color for phase/step title text.
           - instructionTextColor: Color for instructional text.
           - bulletBackground: Background color for instruction bullets.
           - bulletTextColor: Text color for instruction bullets.
           - successColor: Color used for success state.
           - errorColor: Color used for error state.
           - statusMessageColor: Text color for status messages.
         */
        public init(
            cardBackground: Color?,
            headerBackground: Color?,
            dividerColor: Color,
            headerTitleColor: Color,
            headerSubtitleColor: Color,
            providerLogoTint: Color,
            keyIconColorIdle: Color,
            keyIconColorActive: Color,
            keyButtonGradient: [Color],
            keyButtonShadowColor: Color,
            keyButtonShadowRadius: CGFloat,
            keyButtonShadowYOffset: CGFloat,
            progressColor: Color,
            phaseTitleColor: Color,
            instructionTextColor: Color,
            bulletBackground: Color,
            bulletTextColor: Color,
            successColor: Color,
            errorColor: Color,
            statusMessageColor: Color
        ) {
            self.cardBackground = cardBackground
            self.headerBackground = headerBackground
            self.dividerColor = dividerColor
            self.headerTitleColor = headerTitleColor
            self.headerSubtitleColor = headerSubtitleColor
            self.providerLogoTint = providerLogoTint
            self.keyIconColorIdle = keyIconColorIdle
            self.keyIconColorActive = keyIconColorActive
            self.keyButtonGradient = keyButtonGradient
            self.keyButtonShadowColor = keyButtonShadowColor
            self.keyButtonShadowRadius = keyButtonShadowRadius
            self.keyButtonShadowYOffset = keyButtonShadowYOffset
            self.progressColor = progressColor
            self.phaseTitleColor = phaseTitleColor
            self.instructionTextColor = instructionTextColor
            self.bulletBackground = bulletBackground
            self.bulletTextColor = bulletTextColor
            self.successColor = successColor
            self.errorColor = errorColor
            self.statusMessageColor = statusMessageColor
        }

        public static let `default` = UnlockCard(
            cardBackground: nil,
            headerBackground: nil,
            dividerColor: Color(UIColor.separator),
            headerTitleColor: .primary,
            headerSubtitleColor: .secondary,
            providerLogoTint: .secondary,
            keyIconColorIdle: .white,
            keyIconColorActive: .primary,
            keyButtonGradient: [.accentColor.opacity(0.8), .accentColor],
            keyButtonShadowColor: .clear,
            keyButtonShadowRadius: 0,
            keyButtonShadowYOffset: 0,
            progressColor: .accentColor,
            phaseTitleColor: .primary,
            instructionTextColor: .primary,
            bulletBackground: Color(UIColor.systemFill),
            bulletTextColor: .white,
            successColor: .green,
            errorColor: .red,
            statusMessageColor: .primary
        )

        public func with(
            cardBackground: Color? = nil,
            headerBackground: Color? = nil,
            dividerColor: Color? = nil,
            headerTitleColor: Color? = nil,
            headerSubtitleColor: Color? = nil,
            providerLogoTint: Color? = nil,
            keyIconColorIdle: Color? = nil,
            keyIconColorActive: Color? = nil,
            keyButtonGradient: [Color]? = nil,
            keyButtonShadowColor: Color? = nil,
            keyButtonShadowRadius: CGFloat? = nil,
            keyButtonShadowYOffset: CGFloat? = nil,
            progressColor: Color? = nil,
            phaseTitleColor: Color? = nil,
            instructionTextColor: Color? = nil,
            bulletBackground: Color? = nil,
            bulletTextColor: Color? = nil,
            successColor: Color? = nil,
            errorColor: Color? = nil,
            statusMessageColor: Color? = nil
        ) -> Self {
            .init(
                cardBackground: cardBackground ?? self.cardBackground,
                headerBackground: headerBackground ?? self.headerBackground,
                dividerColor: dividerColor ?? self.dividerColor,
                headerTitleColor: headerTitleColor ?? self.headerTitleColor,
                headerSubtitleColor: headerSubtitleColor ?? self.headerSubtitleColor,
                providerLogoTint: providerLogoTint ?? self.providerLogoTint,
                keyIconColorIdle: keyIconColorIdle ?? self.keyIconColorIdle,
                keyIconColorActive: keyIconColorActive ?? self.keyIconColorActive,
                keyButtonGradient: keyButtonGradient ?? self.keyButtonGradient,
                keyButtonShadowColor: keyButtonShadowColor ?? self.keyButtonShadowColor,
                keyButtonShadowRadius: keyButtonShadowRadius ?? self.keyButtonShadowRadius,
                keyButtonShadowYOffset: keyButtonShadowYOffset ?? self.keyButtonShadowYOffset,
                progressColor: progressColor ?? self.progressColor,
                phaseTitleColor: phaseTitleColor ?? self.phaseTitleColor,
                instructionTextColor: instructionTextColor ?? self.instructionTextColor,
                bulletBackground: bulletBackground ?? self.bulletBackground,
                bulletTextColor: bulletTextColor ?? self.bulletTextColor,
                successColor: successColor ?? self.successColor,
                errorColor: errorColor ?? self.errorColor,
                statusMessageColor: statusMessageColor ?? self.statusMessageColor
            )
        }
    }

    /// # Colors
    ///
    /// A semantic palette for all SeamComponents, grouping all color values by purpose (e.g., accent, text, background, status, etc).
    ///
    /// All values can be overridden to match your branding or accessibility requirements.
    ///
    /// - Tip: Use your app's asset catalog or dynamic colors for best results.
    ///
    /// ### Partial Customization
    /// You can easily override just a subset of palette values using the `with(...)` method. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default.
    /// ```swift
    /// let myColors = SeamTheme.Colors.default.with(accent: .orange, error: .pink)
    /// ```
    /// This produces a palette where only the specified colors are changed, and all others are inherited.
    ///
    /// See the `with` builder method for easy partial customization.
    public struct Colors: Sendable, Equatable {
        /// Primary accent color for highlights, buttons, and active elements.
        public var accent: Color
        /// Primary color for text content.
        public var primaryText: Color
        /// Secondary color for less prominent text.
        public var secondaryText: Color
        /// Text color intended for use on dark backgrounds.
        public var primaryTextLight: Color
        /// Text color intended for use on light backgrounds.
        public var primaryTextDark: Color
        /// Color for destructive actions and critical warnings.
        public var danger: Color
        /// Color for error states and messages.
        public var error: Color
        /// Color for caution or warning indicators.
        public var warning: Color
        /// Color for informational highlights (non-destructive notices).
        public var info: Color
        /// Color indicating success states.
        public var success: Color
        /// Subtle fill for borders, separators, and backgrounds.
        public var grayFill: Color
        /// Fill for cards or light containers.
        public var lightFill: Color
        /// Fill for dark backgrounds or overlays.
        public var darkFill: Color
        /// Fill for secondary containers or backgrounds.
        public var secondaryFill: Color
        /// Color for progress indicators and loading states.
        public var progress: Color
        /// Background used for primary content.
        public var primaryBackground: Color
        /// Background used for grouped or alternate rows.
        public var secondaryBackground: Color

        /// Default, system-aligned color palette.
        public static let `default` = Colors(
            accent: .accentColor,
            primaryText: .primary,
            secondaryText: .secondary,
            primaryTextLight: .white,
            primaryTextDark: .black,
            danger: .red,
            error: .red,
            warning: .yellow,
            info: .accentColor,
            success: .green,
            grayFill: Color(UIColor.systemGray),
            lightFill: .white,
            darkFill: .black,
            secondaryFill: Color(UIColor.secondarySystemFill),
            progress: .accentColor,
            primaryBackground: Color(UIColor.systemBackground),
            secondaryBackground: Color(UIColor.secondarySystemBackground)
        )

        /**
         Creates a custom color palette for SeamComponents.

         Use this initializer to override any or all semantic colors used in the UI. This enables full white-labeling, branding, or accessibility adjustments.

         - Parameters:
         - accent: The primary accent color for highlights, buttons, and active elements.
         - primaryText: The main color for text content.
         - secondaryText: Secondary text color for less prominent information.
         - primaryTextLight: Text color for use on dark backgrounds.
         - primaryTextDark: Text color for use on light backgrounds.
         - danger: Used for destructive actions and warnings.
         - error: Used for error states and messages.
         - warning: Used for caution or warning indicators.
         - info: Used for informational highlights.
         - success: Used to indicate success states.
         - grayFill: Used for borders, separators, and subtle backgrounds.
         - lightFill: Used for card or container backgrounds.
         - darkFill: Used for dark backgrounds or overlays.
         - secondaryFill: Used for secondary containers or backgrounds.
         - progress: Used for progress bars and loading indicators.
         - primaryBackground: Used for primary content backgrounds.
         - secondaryBackground: Used for grouped backgrounds or alternate rows.
         */
        public init(accent: Color, primaryText: Color, secondaryText: Color, primaryTextLight: Color, primaryTextDark: Color, danger: Color, error: Color, warning: Color, info: Color, success: Color, grayFill: Color, lightFill: Color, darkFill: Color, secondaryFill: Color, progress: Color, primaryBackground: Color, secondaryBackground: Color) {
            self.accent = accent
            self.primaryText = primaryText
            self.secondaryText = secondaryText
            self.primaryTextLight = primaryTextLight
            self.primaryTextDark = primaryTextDark
            self.danger = danger
            self.error = error
            self.warning = warning
            self.info = info
            self.success = success
            self.grayFill = grayFill
            self.lightFill = lightFill
            self.darkFill = darkFill
            self.secondaryFill = secondaryFill
            self.progress = progress
            self.primaryBackground = primaryBackground
            self.secondaryBackground = secondaryBackground
        }
        /**
         Returns a copy of this color palette, overriding only the specified values.

         This builder enables partial customization of your palette—set only the colors you want to change, and all others will be inherited from the original. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default.

         ### Example
         ```swift
         let myColors = SeamTheme.Colors.default.with(accent: .orange, error: .pink)
         ```
         - Parameters:
         - accent: The primary accent color for highlights, buttons, and active elements (optional).
         - primaryText: The main color for text content (optional).
         - secondaryText: Secondary text color (optional).
         - primaryTextLight: Text color for use on dark backgrounds (optional).
         - primaryTextDark: Text color for use on light backgrounds (optional).
         - danger: Used for destructive actions and warnings (optional).
         - error: Used for error states and messages (optional).
         - warning: Used for caution or warning indicators (optional).
         - info: Used for informational highlights (optional).
         - success: Used to indicate success states (optional).
         - grayFill: Used for borders, separators, and subtle backgrounds (optional).
         - lightFill: Used for card or container backgrounds (optional).
         - darkFill: Used for dark backgrounds or overlays (optional).
         - secondaryFill: Used for secondary containers or backgrounds (optional).
         - progress: Used for progress bars and loading indicators (optional).
         - primaryBackground: Used for primary content backgrounds (optional).
         - secondaryBackground: Used for grouped backgrounds or alternate rows (optional).
         - Returns: A new `Colors` instance with selected values replaced.
         */
        public func with(
            accent: Color? = nil,
            primaryText: Color? = nil,
            secondaryText: Color? = nil,
            primaryTextLight: Color? = nil,
            primaryTextDark: Color? = nil,
            danger: Color? = nil,
            error: Color? = nil,
            warning: Color? = nil,
            info: Color? = nil,
            success: Color? = nil,
            grayFill: Color? = nil,
            lightFill: Color? = nil,
            darkFill: Color? = nil,
            secondaryFill: Color? = nil,
            progress: Color? = nil,
            primaryBackground: Color? = nil,
            secondaryBackground: Color? = nil
        ) -> Self {
            .init(
                accent: accent ?? self.accent,
                primaryText: primaryText ?? self.primaryText,
                secondaryText: secondaryText ?? self.secondaryText,
                primaryTextLight: primaryTextLight ?? self.primaryTextLight,
                primaryTextDark: primaryTextDark ?? self.primaryTextDark,
                danger: danger ?? self.danger,
                error: error ?? self.error,
                warning: warning ?? self.warning,
                info: info ?? self.info,
                success: success ?? self.success,
                grayFill: grayFill ?? self.grayFill,
                lightFill: lightFill ?? self.lightFill,
                darkFill: darkFill ?? self.darkFill,
                secondaryFill: secondaryFill ?? self.secondaryFill,
                progress: progress ?? self.progress,
                primaryBackground: primaryBackground ?? self.primaryBackground,
                secondaryBackground: secondaryBackground ?? self.secondaryBackground
            )
        }
        // See also: Use the `with` builder for partial customization.
    }

    /// # Fonts
    ///
    /// A semantic palette for all SeamComponents, grouping all font roles to ensure a consistent typographic hierarchy across all UI.
    /// All font roles match iOS system conventions and are fully Dynamic Type compatible.
    ///
    /// ### Partial Customization
    /// You can override just the fonts you need using the `with(...)` builder. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default.
    /// ```swift
    /// let myFonts = SeamTheme.Fonts.default.with(largeTitle: .system(size: 40, weight: .bold))
    /// ```
    /// This allows you to change only specific roles while inheriting the rest.
    ///
    /// See the `with` builder method for easy partial customization.
    public struct Fonts: Sendable, Equatable {
        /// Largest headings (prominent page titles).
        public var largeTitle: Font
        /// Primary section titles.
        public var title: Font
        /// Secondary section titles.
        public var title2: Font
        /// Tertiary section titles.
        public var title3: Font
        /// Emphasized headings and important labels.
        public var headline: Font
        /// Supporting subheadings.
        public var subheadline: Font
        /// Standard body text.
        public var body: Font
        /// Short callouts and supporting labels.
        public var callout: Font
        /// Auxiliary or meta information.
        public var footnote: Font
        /// Caption text (small annotations).
        public var caption: Font
        /// Smaller caption variant.
        public var caption2: Font
        /// Prominent action titles (e.g., primary buttons).
        public var actionTitle: Font
        /// Section headers in grouped lists.
        public var sectionHeader: Font

        /// Default font palette aligned to iOS system roles (Dynamic Type compatible).
        public static let `default` = Fonts(
            largeTitle: .largeTitle.weight(.bold),
            title: .title.weight(.semibold),
            title2: .title2.weight(.medium),
            title3: .title3,
            headline: .headline,
            subheadline: .subheadline.weight(.semibold),
            body: .body,
            callout: .callout,
            footnote: .footnote,
            caption: .caption,
            caption2: .caption2,
            actionTitle: .headline,
            sectionHeader: .footnote.weight(.semibold)
        )

        /**
         Creates a custom font palette for SeamComponents.

         Use this initializer to override any or all semantic font roles in the UI. This enables brand-specific typography or accessibility enhancements.

         - Parameters:
         - largeTitle: Used for the largest headings.
         - title: Used for primary section titles.
         - title2: Used for secondary section titles.
         - title3: Used for tertiary section titles.
         - headline: Used for headlines and key information.
         - subheadline: Used for supporting headlines.
         - body: Used for main body text.
         - callout: Used for callouts, labels, or supporting info.
         - footnote: Used for footnotes or auxiliary text.
         - caption: Used for captions.
         - caption2: Used for secondary caption text.
         - actionTitle: Used for prominent action buttons or links.
         - sectionHeader: Used for section headers in grouped lists.
         */
        public init(largeTitle: Font, title: Font, title2: Font, title3: Font, headline: Font, subheadline: Font, body: Font, callout: Font, footnote: Font, caption: Font, caption2: Font, actionTitle: Font, sectionHeader: Font) {
            self.largeTitle = largeTitle
            self.title = title
            self.title2 = title2
            self.title3 = title3
            self.headline = headline
            self.subheadline = subheadline
            self.body = body
            self.callout = callout
            self.footnote = footnote
            self.caption = caption
            self.caption2 = caption2
            self.actionTitle = actionTitle
            self.sectionHeader = sectionHeader
        }
        /**
         Returns a copy of this font palette, overriding only the specified values.

         This builder enables partial customization—set only the font roles you wish to override, and all other values are inherited from the original. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default.

         ### Example
         ```swift
         let myFonts = SeamTheme.Fonts.default.with(largeTitle: .system(size: 40, weight: .bold))
         ```
         - Parameters:
         - largeTitle: Font for the largest headings (optional).
         - title: Font for primary section titles (optional).
         - title2: Font for secondary section titles (optional).
         - title3: Font for tertiary section titles (optional).
         - headline: Font for headlines (optional).
         - subheadline: Font for supporting headlines (optional).
         - body: Font for main body text (optional).
         - callout: Font for callouts, labels, or supporting info (optional).
         - footnote: Font for footnotes or auxiliary text (optional).
         - caption: Font for captions (optional).
         - caption2: Font for secondary caption text (optional).
         - actionTitle: Font for prominent action buttons or links (optional).
         - sectionHeader: Font for section headers in grouped lists (optional).
         - Returns: A new `Fonts` instance with selected values replaced.
         */
        public func with(
            largeTitle: Font? = nil,
            title: Font? = nil,
            title2: Font? = nil,
            title3: Font? = nil,
            headline: Font? = nil,
            subheadline: Font? = nil,
            body: Font? = nil,
            callout: Font? = nil,
            footnote: Font? = nil,
            caption: Font? = nil,
            caption2: Font? = nil,
            actionTitle: Font? = nil,
            sectionHeader: Font? = nil
        ) -> Self {
            .init(
                largeTitle: largeTitle ?? self.largeTitle,
                title: title ?? self.title,
                title2: title2 ?? self.title2,
                title3: title3 ?? self.title3,
                headline: headline ?? self.headline,
                subheadline: subheadline ?? self.subheadline,
                body: body ?? self.body,
                callout: callout ?? self.callout,
                footnote: footnote ?? self.footnote,
                caption: caption ?? self.caption,
                caption2: caption2 ?? self.caption2,
                actionTitle: actionTitle ?? self.actionTitle,
                sectionHeader: sectionHeader ?? self.sectionHeader
            )
        }
        // See also: Use the `with` builder for partial customization.
    }

    /// The color palette for this theme.
    public var colors: Colors

    /// The font palette for this theme.
    public var fonts: Fonts

    /// The key card style for this theme.
    public var keyCard: KeyCard

    /// The default theme matching system colors, fonts, and the default key card, toast, and unlock card styles.
    ///
    /// - Note: If you do not provide a custom theme, SeamComponents will use this default.
    public static let `default` = SeamTheme()

    /// The toast style for this theme.
    public var toast: Toast

    /// The unlock card style for this theme.
    public var unlockCard: UnlockCard

    /**
     Creates a new `SeamTheme` with the specified color, font, key card, toast, and unlock card palettes.

     Use this initializer to provide custom theme palettes. Typically, you will use this to supply a custom `colors`, `fonts`, `keyCard`, `toast`, and/or `unlockCard` instance to override the default appearance for all SeamComponents.

     For most cases, you can take advantage of partial customization by using the `with(...)` methods on `Colors`, `Fonts`, `KeyCard`, `Toast`, and `UnlockCard` to override only what you need. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default.
     ```swift
     let theme = SeamTheme(
     colors: .default.with(accent: .orange),
     fonts: .default.with(largeTitle: .system(size: 36, weight: .bold)),
     keyCard: .default.with(cornerRadius: 20)
     )
     ```

     - Parameters:
     - colors: The color palette to use for all UI elements. See ``SeamTheme/Colors/init(accent:primaryText:secondaryText:primaryTextLight:primaryTextDark:danger:error:warning:info:success:grayFill:lightFill:darkFill:secondaryFill:progress:secondaryBackground:)`` for details.
     - fonts: The font palette for all typography. See ``SeamTheme/Fonts/init(largeTitle:title:title2:title3:headline:subheadline:body:callout:footnote:caption:caption2:actionTitle:sectionHeader:)`` for details.
     - keyCard: The key card style for key card UI elements. See ``SeamTheme/KeyCard/init(backgroundGradient:accentColor:logoAssetName:cornerRadius:shadowColor:shadowRadius:shadowYOffset:)`` for details.
     - toast: The toast style for transient banners. See ``SeamTheme/Toast`` for details.
     - unlockCard: The unlock card style used by SeamUnlockCardView. See ``SeamTheme/UnlockCard``.
     */
    public init(
        colors: SeamTheme.Colors = .default,
        fonts: SeamTheme.Fonts = .default,
        keyCard: SeamTheme.KeyCard = .default,
        toast: SeamTheme.Toast = .default,
        unlockCard: SeamTheme.UnlockCard = .default
    ) {
        self.colors = colors
        self.fonts = fonts
        self.keyCard = keyCard
        self.toast = toast
        self.unlockCard = unlockCard
    }

    /**
     Returns a copy of this theme, overriding only the specified nested palettes.

     This builder enables partial customization at the theme level—set only the `colors`, `fonts`, `keyCard`, `toast`, or `unlockCard` you want to override, and all other values are inherited from the original. This means you can easily change just a few aspects of the appearance while inheriting all other styles from the theme’s default or an existing theme.

     ### Example
     ```swift
     let customTheme = SeamTheme.default.with(
     colors: .default.with(accent: .orange),
     keyCard: .default.with(cornerRadius: 24)
     )
     ```
     - Parameters:
     - colors: The color palette to use (optional). If not specified, inherits from the current theme.
     - fonts: The font palette to use (optional). If not specified, inherits from the current theme.
     - keyCard: The key card style to use (optional). If not specified, inherits from the current theme.
     - toast: The toast style to use (optional). If not specified, inherits from the current theme.
     - unlockCard: The unlock card style to use (optional). If not specified, inherits from the current theme.
     - Returns: A new `SeamTheme` instance with selected palettes replaced.
     */
    public func with(
        colors: Colors? = nil,
        fonts: Fonts? = nil,
        keyCard: KeyCard? = nil,
        toast: Toast? = nil,
        unlockCard: UnlockCard? = nil
    ) -> Self {
        .init(
            colors: colors ?? self.colors,
            fonts: fonts ?? self.fonts,
            keyCard: keyCard ?? self.keyCard,
            toast: toast ?? self.toast,
            unlockCard: unlockCard ?? self.unlockCard
        )
    }
}

// MARK: - SwiftUI EnvironmentKey for SeamTheme

/// The environment key used by SeamComponents to read the current theme.
///
/// Inject a theme at any level of your view hierarchy to customize appearance:
/// ```swift
/// .environment(\.seamTheme, customTheme)
/// ```
/// - Important: All SeamComponents automatically read from this value.
private struct SeamThemeKey: EnvironmentKey {
    static let defaultValue: SeamTheme = .default
}

public extension EnvironmentValues {
    /// The theme currently in effect for SeamComponents.
    ///
    /// Override with `.environment(\.seamTheme, ...)` to apply a custom theme.
    var seamTheme: SeamTheme {
        get { self[SeamThemeKey.self] }
        set { self[SeamThemeKey.self] = newValue }
    }
}


// MARK: - Previews

#if DEBUG

#Preview("Theme Colors") {
    let theme = SeamTheme.default
    let colors = [
        ("primaryText", theme.colors.primaryText),
        ("secondaryText", theme.colors.secondaryText),
        ("primaryTextLight", theme.colors.primaryTextLight),
        ("primaryTextDark", theme.colors.primaryTextDark),
        ("danger", theme.colors.danger),
        ("grayFill", theme.colors.grayFill),
        ("lightFill", theme.colors.lightFill),
        ("darkFill", theme.colors.darkFill),
        ("secondaryFill", theme.colors.secondaryFill),
        ("progress", theme.colors.progress),
        ("secondaryBackground", theme.colors.secondaryBackground)
    ]
    // Visual swatches for key theme colors.
    ScrollView {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(colors, id: \.0) { name, color in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(theme.colors.grayFill, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color)
                        )
                        .frame(width: 44, height: 44)
                    Text(name)
                        .font(theme.fonts.body)
                    Spacer()
                }
                Divider()
            }
        }
        .padding()
    }
    .padding()
}

#Preview("Theme Fonts") {
    let theme = SeamTheme.default
    let fonts = [
        ("largeTitle", theme.fonts.largeTitle),
        ("title", theme.fonts.title),
        ("title2", theme.fonts.title2),
        ("title3", theme.fonts.title3),
        ("headline", theme.fonts.headline),
        ("subheadline", theme.fonts.subheadline),
        ("body", theme.fonts.body),
        ("callout", theme.fonts.callout),
        ("footnote", theme.fonts.footnote),
        ("caption", theme.fonts.caption),
        ("caption2", theme.fonts.caption2),
        ("actionTitle", theme.fonts.actionTitle),
        ("sectionHeader", theme.fonts.sectionHeader)
    ]
    // Samples for each semantic font role.
    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(fonts, id: \.0) { name, font in
                Text(name)
                    .font(font)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
#endif
