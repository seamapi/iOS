import SwiftUI

///
/// # SeamKeyCardStyle
///
/// Encapsulates all visual style parameters for a hotel key card brand.
///
/// - Parameters:
///   - backgroundGradient: Gradient colors for the card background (typically two or more colors).
///   - accentColor: Accent color for the top accent bar.
///   - logoAssetName: Asset name of the brand or property logo.
///   - cornerRadius: Corner radius for the card container (default 16).
///   - shadow: Shadow configuration for card elevation (default: `.black.opacity(0.2)`, radius 8, x 0, y 4).
///
/// ## Visual Description
/// By default, backgrounds use a custom “Dune” gradient inspired by sand dunes from above,
/// creating a premium, tactile look suitable for hotel brands.
///
/// ## Predefined Styles
/// - `.grey`: Neutral, universal.
/// - `.purple`: Modern, branded accent.
/// - `.yellow`: Bright, energetic accent.
///
/// ## Extending
/// To define your own style:
/// ```swift
/// extension SeamKeyCardStyle {
///   static let myBrand = SeamKeyCardStyle(
///     backgroundGradient: [Color.indigo, Color.cyan],
///     accentColor: .green,
///     logoAssetName: "MyBrandLogo"
///   )
/// }
/// ```
///
/// A set of closures defining the visual appearance of a key card, parameterized by the current theme.
public struct SeamKeyCardStyle: Sendable {
    /// A closure that returns the background gradient colors for a given theme.
    /// - Parameter theme: The current ``SeamTheme``.
    /// - Returns: An ordered array of colors used to render the card background.
    public var backgroundGradient: @Sendable (SeamTheme) -> [Color]
    /// A closure that resolves the accent color for the top accent bar.
    /// - Parameter theme: The current ``SeamTheme``.
    /// - Returns: The accent color.
    public var accentColor: @Sendable (SeamTheme) -> Color
    /// A closure that resolves the asset name of the brand or property logo.
    /// - Parameter theme: The current ``SeamTheme``.
    /// - Returns: The image asset name to load.
    public var logoAssetName: @Sendable (SeamTheme) -> String
    /// A closure that resolves the corner radius for the card container.
    /// - Parameter theme: The current ``SeamTheme``.
    /// - Returns: The corner radius in points.
    public var cornerRadius: @Sendable (SeamTheme) -> CGFloat
    /// A closure that resolves the drop‑shadow configuration for the card.
    /// - Parameter theme: The current ``SeamTheme``.
    /// - Returns: A ``SeamKeyCardStyle/Shadow`` value describing the shadow.
    public var shadow: @Sendable (SeamTheme) -> Shadow

    /// A lightweight description of a drop shadow used by key cards.
    ///
    /// - Parameters:
    ///   - color: The shadow color.
    ///   - radius: The blur radius.
    ///   - x: The horizontal offset.
    ///   - y: The vertical offset.
    public struct Shadow: Sendable {
        /// The color of the shadow.
        public let color: Color
        /// The blur radius applied to the shadow.
        public let radius: CGFloat
        /// The horizontal offset of the shadow.
        public let x: CGFloat
        /// The vertical offset of the shadow.
        public let y: CGFloat
        /// Creates a shadow description.
        /// - Parameters:
        ///   - color: The shadow color.
        ///   - radius: The blur radius.
        ///   - x: The horizontal offset.
        ///   - y: The vertical offset.
        public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
    /// Returns a style constructed from values in the given theme.
    /// - Parameter theme: The theme from which to derive visual values.
    /// - Returns: A theme‑driven ``SeamKeyCardStyle``.
    public static func `default`(theme: SeamTheme) -> SeamKeyCardStyle {
        SeamKeyCardStyle(
            backgroundGradient: { $0.keyCard.backgroundGradient } ,
            accentColor: { $0.keyCard.accentColor },
            logoAssetName: { $0.keyCard.logoAssetName },
            cornerRadius: { $0.keyCard.cornerRadius },
            shadow: { .init(color: $0.keyCard.shadowColor,
                            radius: $0.keyCard.shadowRadius,
                            x: 0,
                            y: $0.keyCard.shadowYOffset) }
        )
    }

    /// Creates a customizable card style.
    ///
    /// - Parameters:
    ///   - backgroundGradient: Closure that returns the gradient colors for the card background.
    ///   - accentColor: Closure that returns the accent bar color.
    ///   - logoAssetName: Closure that returns the logo asset name.
    ///   - cornerRadius: Closure that returns the container corner radius. Default: `16`.
    ///   - shadow: Closure that returns the shadow configuration. Default uses the theme’s shadow values.
    public init(backgroundGradient: @Sendable @escaping (SeamTheme) -> [Color],
                accentColor: @Sendable @escaping (SeamTheme) -> Color,
                logoAssetName: @Sendable @escaping (SeamTheme) -> String,
                cornerRadius: @Sendable @escaping (SeamTheme) -> CGFloat = { _ in 16 },
                shadow: @Sendable @escaping (SeamTheme) -> Shadow = { .init(color: $0.keyCard.shadowColor.opacity(0.2),
                                                                            radius: $0.keyCard.shadowRadius,
                                                                            x: 0,
                                                                            y: $0.keyCard.shadowYOffset) }
    ) {
        self.backgroundGradient = backgroundGradient
        self.accentColor = accentColor
        self.logoAssetName = logoAssetName
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
}

public extension SeamKeyCardStyle {
    /// A neutral, universally styled card using a muted gray gradient with an orange accent and a default icon.
    static let grey = SeamKeyCardStyle(
        backgroundGradient: { _ in [
            Color.gray.opacity(0.55),
            Color.gray.opacity(0.25)
        ] },
        accentColor: { _ in Color.orange },
        logoAssetName: { _ in "Icon" }
    )

    /// A modern style with a purple gradient and blue accent, suitable for branded experiences.
    static let purple = SeamKeyCardStyle(
        backgroundGradient: { _ in [
            Color.purple.opacity(0.85),
            Color.purple.opacity(0.65)
        ] },
        accentColor: { _ in Color.blue },
        logoAssetName: { _ in "Icon"}
    )

    /// A bright, energetic yellow style for cheerful, attention‑grabbing cards.
    static let yellow = SeamKeyCardStyle(
        backgroundGradient: { _ in [
            Color.yellow.opacity(0.85),
            Color.yellow.opacity(0.65)
        ] },
        accentColor: { _ in Color.yellow },
        logoAssetName: { _ in "Icon" }
    )
}

///
/// # SeamKeyCardViewModel
///
/// Bundles all the content and branding for a single key card display:
/// - Hotel/property name
/// - Room label (e.g. room number)
/// - Formatted checkout info (e.g. “Fri, Jun 21 at 11:00 AM”)
/// - Visual style (see `SeamKeyCardStyle`)
/// - Errors (for overlaying status badges, e.g. expired, requires action)
///
/// - Use `.init(credential:)` to create from your domain model.
/// - Add a static `.mock` for previewing.
///
/// ## Example
/// ```swift
/// let vm = SeamKeyCardViewModel(
///   hotelName: "Example Hotel",
///   roomLabel: "312",
///   checkoutText: "Fri, Jun 21, 4:00 PM",
///   style: .purple,
///   errors: [.expired]
/// )
/// ```
public struct SeamKeyCardViewModel {
    /// Display name of the hotel or property.
    public var hotelName: String
    /// User‑visible room label (e.g., room number).
    public var roomLabel: String
    /// Formatted checkout date/time string.
    public var checkoutText: String
    /// Visual style parameters for the card.
    public var style: SeamKeyCardStyle
    /// Error or status conditions. When non‑empty, the first error is rendered as a badge.
    public var errors: [SeamAccessCredentialError]

    /// Creates a view model with explicit display values.
    /// - Parameters:
    ///   - hotelName: Display name of the property.
    ///   - roomLabel: The room number or label.
    ///   - checkoutText: Formatted checkout date and time.
    ///   - style: A ``SeamKeyCardStyle`` defining colors, logo, and metrics.
    ///   - errors: Credential error/status list for overlay presentation.
    public init(hotelName: String,
                roomLabel: String,
                checkoutText: String,
                style: SeamKeyCardStyle,
                errors: [SeamAccessCredentialError]) {
        self.hotelName = hotelName
        self.roomLabel = roomLabel
        self.checkoutText = checkoutText
        self.style = style
        self.errors = errors
    }

    /// Initializes from a ``SeamAccessCredential`` snapshot.
    ///
    /// Maps ``SeamAccessCredential/location`` to ``hotelName``, ``SeamAccessCredential/name`` to ``roomLabel``,
    /// derives ``checkoutText`` from ``SeamAccessCredential/expiry``, applies the theme default style, and
    /// forwards ``SeamAccessCredential/errors``.
    public init(credential: SeamAccessCredential) {
        let checkoutText = credential.expiry?.seamHumanReadableString ?? ""

        self.hotelName = credential.location
        self.roomLabel = credential.name
        self.checkoutText = checkoutText
        self.style = .default(theme: .default)
        self.errors = credential.errors
    }
}


/// # SeamKeyCardView
///
/// A flexible and visually rich SwiftUI view for displaying digital hotel room key cards.
///
/// ## Visual Appearance
/// The card features a softly curved, dune-inspired gradient background with a top accent bar, property logo, and clearly laid out room and checkout information. If needed, a status badge overlays the card to indicate important states (e.g., expired or action required).
///
/// ## Features
/// - **Custom Branding**: Style cards with brand colors, logos, gradients, and accent bars using `SeamKeyCardStyle`.
/// - **Customizable Error Presentation**: The appearance, icon, text, and actions for status and error overlays (e.g., expired, action required) can be tailored using the `SeamAccessCredentialErrorStyle` parameter. Pass a custom style to the `errorStyle:` argument to change badge colors, iconography, or messages for specific errors at the app or view level.
/// - **Status Overlays**: Automatically shows badges and overlays for error or status conditions (e.g., expired, action required), using `SeamAccessCredentialError` and `SeamStatusBadge`.
/// - **Composability**: Easily integrates into lists, grids, or detail screens—use as a standalone view or with higher-level containers like `SeamCredentialsView`.
/// - **Accessibility**: All text uses semantic styles and supports dynamic type, high-contrast, and VoiceOver. Visuals are designed for clarity with system accessibility settings.
///
/// ## Usage
/// Provide data and appearance via a `SeamKeyCardViewModel`. Use in a grid, list, or by itself:
///
/// ```swift
/// SeamKeyCardView(
///   viewModel: .init(
///     hotelName: "Hotel X",
///     roomLabel: "245",
///     checkoutText: "Sat, Jun 22, 12:00 PM",
///     style: .grey,
///     errors: []
///   ),
///   errorStyle: .default
/// )
/// .frame(width: 300, height: 200)
/// ```
///
/// ## Notes
/// - Designed for iOS 17+ with Swift 5.9 and SwiftUI Observation macros.
/// - Integrates seamlessly with other SeamComponents.
/// - Customizable for different brands or property styles.
public struct SeamKeyCardView: View {
    /// Content, branding, and status for this card.
    public let viewModel: SeamKeyCardViewModel
    /// Strategy for rendering error/status badges and messages.
    public let errorStyle: SeamAccessCredentialErrorStyle
    @Environment(\.seamTheme) private var theme

    /// Creates a new key card view.
    /// - Parameters:
    ///   - viewModel: The model that supplies display text, style, and errors.
    ///   - errorStyle: Optional presentation strategy for errors. Defaults to ``SeamAccessCredentialErrorStyle/default``.
    public init(
        viewModel: SeamKeyCardViewModel,
        errorStyle: SeamAccessCredentialErrorStyle = .default
    ) {
        self.viewModel = viewModel
        self.errorStyle = errorStyle
    }

    public var body: some View {
        ZStack {
            SeamDuneBackground(
                colors: viewModel.style.backgroundGradient(theme),
                cornerRadius: viewModel.style.cornerRadius(theme)
            )

            // accent bar
            SeamKeyCardAccentBar(
                color: viewModel.style.accentColor(theme),
                cornerRadius: viewModel.style.cornerRadius(theme)
            )

            // brand logo
            SeamKeyCardLogo(imageName: viewModel.style.logoAssetName(theme))


            // text content
            VStack {
                if let error = viewModel.errors.first {
                    HStack {
                        SeamStatusBadge(
                            iconName: errorStyle.systemIcon(error, theme),
                            text: errorStyle.shortDescription(error),
                            color: errorStyle.iconColor(error, theme)
                        )
                        Spacer()
                    }
                    .padding()
                }
                Spacer()
                SeamKeyCardTextBlock(
                    hotelName: viewModel.hotelName,
                    roomLabel: viewModel.roomLabel,
                    checkoutText: viewModel.checkoutText
                )
            }

            /// When errors are present, apply a material overlay to de‑emphasize card content behind the badge.
            if !viewModel.errors.isEmpty {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.7))
            }
        }
        .cornerRadius(viewModel.style.cornerRadius(theme))
        .shadow(
            color: viewModel.style.shadow(theme).color,
            radius: viewModel.style.shadow(theme).radius,
            x: viewModel.style.shadow(theme).x,
            y: viewModel.style.shadow(theme).y
        )
        /// Fixed height chosen to maintain a consistent card aspect in grids and lists.
        .frame(height: 200)
    }
}



/// A thin accent bar at the top of the card, color and width set by the brand style.
struct SeamKeyCardAccentBar: View {
    let color: Color
    let cornerRadius: CGFloat

    /// Creates an accent bar.
    /// - Parameters:
    ///   - color: The bar color.
    ///   - cornerRadius: The card corner radius used to align the bar.
    init(color: Color, cornerRadius: CGFloat) {
        self.color = color
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Rectangle()
                .fill(color)
                .frame(width: 110, height: 8)
            Rectangle()
                .fill(.clear)
                .frame(maxHeight: .infinity)
        }
    }
}

/// Displays a resizable logo image in the top-trailing corner of the card.
struct SeamKeyCardLogo: View {
    let imageName: String

    /// Creates a logo view.
    /// - Parameter imageName: The asset name of the logo image.
    init(imageName: String) {
        self.imageName = imageName
    }

    var body: some View {
        // Attempt to load the asset from the module bundle first, then fall back to the main bundle.
        ZStack {
            Image(imageName, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            Image(imageName, bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

/// Shows property name, room, and checkout info aligned bottom-leading.
struct SeamKeyCardTextBlock: View {
    /// The property name displayed at the bottom of the card.
    let hotelName: String
    /// The user‑readable room label.
    let roomLabel: String
    /// The formatted checkout string.
    let checkoutText: String
    @Environment(\.seamTheme) private var theme

    /// Creates a text block for the card footer.
    /// - Parameters:
    ///   - hotelName: The property name.
    ///   - roomLabel: The room label (e.g., number).
    ///   - checkoutText: The formatted checkout information.
    init(hotelName: String,
         roomLabel: String,
         checkoutText: String) {
        self.hotelName = hotelName
        self.roomLabel = roomLabel
        self.checkoutText = checkoutText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(hotelName)
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.primaryText)

            HStack {
                Text("ROOM")
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryText)
                Text(roomLabel)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.primaryText)
            }

            HStack {
                Text("EXPIRES AT")
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryText)
                Text(checkoutText)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.primaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
    }
}

#if DEBUG
// Previews of various key card states and styles for fast design iteration.
// Use SeamKeyCardViewModel.mock in DEBUG to test different configurations.
#Preview {
    ScrollView(.vertical) {
        VStack(spacing: 16) {
            SeamKeyCardView(
                viewModel: .init(
                    hotelName: "San Diego Grey Del Mar",
                    roomLabel: "Room 1048",
                    checkoutText: "Fri, Jun 21 at 4:00 PM",
                    style: .grey,
                    errors: []
                ),
                errorStyle: .default
            )
            let errors: [(SeamAccessCredentialError, String)] = [
                (.awaitingLocalCredential, "awaitingLocalCredential"),
                (.expired, "expired"),
                (.unknown, "unknown"),
                (.userInteractionRequired(.completeOtpAuthorization(otpUrl: URL(string: "www.apple.com")!)), "completeOtpAuthorization"),
                (.userInteractionRequired(.enableInternet), "enableInternet"),
                (.userInteractionRequired(.enableBluetooth), "enableBluetooth"),
                (.userInteractionRequired(.grantBluetoothPermission), "grantBluetoothPermission"),
            ]
            ForEach(errors, id: \.self.0) { error in
                SeamKeyCardView(
                    viewModel: .init(
                        hotelName: "Hotel Error: \(error.1)",
                        roomLabel: "Room 308",
                        checkoutText: "Sun, Jun 23 at 10:00 AM",
                        style: .default(theme: SeamTheme.previewTheme),
                        errors: [error.0]
                    ),
                    errorStyle: .default
                )
            }
        }
        .padding()
    }
    .environment(\.seamTheme, SeamTheme.previewTheme)
}

#Preview("Accent Bar") {
    SeamKeyCardAccentBar(color: .orange, cornerRadius: 16)
        .frame(height: 8)
        .environment(\.seamTheme, SeamTheme.previewTheme)
}

#Preview("Logo") {
    SeamKeyCardLogo(imageName: "Icon")
        .frame(width: 60, height: 60)
        .environment(\.seamTheme, SeamTheme.previewTheme)
}

#Preview("Text Block") {
    SeamKeyCardTextBlock(
        hotelName: "Hotel Example",
        roomLabel: "101",
        checkoutText: "Today at 4 PM"
    )
    .frame(width: 300, height: 100)
    .environment(\.seamTheme, SeamTheme.previewTheme)
}

#Preview("Custom Error Style") {
    let customErrorStyle = SeamAccessCredentialErrorStyle(
        shortDescription: { error  in
            if case .expired = error { return "No Longer Valid" }
            return SeamAccessCredentialErrorStyle.default.shortDescription(error)
        },
        iconColor: SeamAccessCredentialErrorStyle.default.iconColor,
        systemIcon: SeamAccessCredentialErrorStyle.default.systemIcon,
        message: SeamAccessCredentialErrorStyle.default.message,
        title: SeamAccessCredentialErrorStyle.default.title,
        primaryActionTitle: SeamAccessCredentialErrorStyle.default.primaryActionTitle,
        primaryAction: SeamAccessCredentialErrorStyle.default.primaryAction
    )
    SeamKeyCardView(
        viewModel: .init(
            hotelName: "Custom Error Style Hotel",
            roomLabel: "Room 420",
            checkoutText: "Tomorrow at 2:00 PM",
            style: .yellow,
            errors: [.expired]
        ),
        errorStyle: customErrorStyle
    )
    .environment(\.seamTheme, SeamTheme.previewTheme)
}
#endif
