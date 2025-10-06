import Foundation
import UIKit
@preconcurrency import CoreBluetooth
import SwiftUI


// MARK: - SeamAccessCredentialErrorStyle

/// Controls the presentation details for each `SeamAccessCredentialError`.
/// Consumers can override icons, colors, text, and actions for different error types.
/// Use the default style for out-of-the-box branding, or inject your own for custom error presentation.
public struct SeamAccessCredentialErrorStyle : Sendable {
    /// Returns the short badge/label text for the given error.
    public var shortDescription: @Sendable (SeamAccessCredentialError) -> LocalizedStringKey
    /// Returns the icon color for the given error.
    public var iconColor: @Sendable (SeamAccessCredentialError, SeamTheme) -> Color
    /// Returns the SF Symbol name for the error icon.
    public var systemIcon: @Sendable (SeamAccessCredentialError, SeamTheme) -> String
    /// Returns a user-facing error message for alerts/sheets.
    public var message: @Sendable (SeamAccessCredentialError) -> LocalizedStringKey
    /// Returns a concise title describing how to resolve the error.
    public var title: @Sendable (SeamAccessCredentialError) -> LocalizedStringKey
    /// Returns the action button title, if any, for the error.
    public var primaryActionTitle: @Sendable (SeamAccessCredentialError) -> LocalizedStringKey?
    /// Returns the corrective action closure for the error, if any, for the error.
    public var primaryAction: @Sendable (SeamAccessCredentialError) -> (() -> Void)

    /// Create a style with custom mapping closures for each property.
    public init(
        shortDescription: @Sendable @escaping (SeamAccessCredentialError) -> LocalizedStringKey,
        iconColor: @Sendable @escaping (SeamAccessCredentialError, SeamTheme) -> Color,
        systemIcon: @Sendable @escaping (SeamAccessCredentialError, SeamTheme) -> String,
        message: @Sendable @escaping (SeamAccessCredentialError) -> LocalizedStringKey,
        title: @Sendable @escaping (SeamAccessCredentialError) -> LocalizedStringKey,
        primaryActionTitle: @Sendable @escaping (SeamAccessCredentialError) -> LocalizedStringKey?,
        primaryAction: @Sendable @escaping (SeamAccessCredentialError) -> (() -> Void)
    ) {
        self.shortDescription = shortDescription
        self.iconColor = iconColor
        self.systemIcon = systemIcon
        self.message = message
        self.title = title
        self.primaryActionTitle = primaryActionTitle
        self.primaryAction = primaryAction
    }

    /// The default error presentation style used by SeamComponents.
    /// This style requires a `SeamTheme` parameter to provide theme-driven presentation.
    public static let `default` = SeamAccessCredentialErrorStyle(
        shortDescription: { $0.shortDescription },
        iconColor: { error, theme in error.iconColor(theme: theme) },
        systemIcon: { error, _ in error.systemIcon },
        message: { $0.message },
        title: { $0.title },
        primaryActionTitle: { $0.primaryActionTitle },
        primaryAction: { $0.primaryAction }
    )
}


/// Provides computed properties and user interface helpers for presenting `SeamAccessCredentialError` values in SwiftUI views.
/// All presentation logic is now theme-driven and must be called from a SwiftUI view (or similar) that has access to the theme.
public extension SeamAccessCredentialError {
    /// A concise, user-facing summary of the error, suitable for status badges or table/list displays.
    var shortDescription: LocalizedStringKey {
        switch self {
        case .awaitingLocalCredential:
            "Processing"
        case .contactSeamSupport:
            "Contact Support"
        case .unsupportedDevice:
            "Unsupported Device"
        case .expired:
            "Expired"
        case .userInteractionRequired(let interaction):
            switch interaction {
            case .completeOtpAuthorization:
                "Enter Verification Code"
            case .enableInternet:
                "Enable Internet Access"
            case .enableBluetooth:
                "Enable Bluetooth"
            case .grantBluetoothPermission:
                "Grant Bluetooth Permission"
            case .appRestartRequired:
                "App Restart Required"
            }
        case .unknown:
            "Unknown Issue"
        }

    }
    /// The color to use for a status icon or badge representing this error.
    /// Colors are chosen for visual clarity and to help users distinguish between different error states.
    func iconColor(theme: SeamTheme) -> Color {
        switch self {
        case .awaitingLocalCredential:
            theme.colors.info
        case .contactSeamSupport:
            theme.colors.error
        case .unsupportedDevice:
            theme.colors.error
        case .expired:
            theme.colors.error
        case .userInteractionRequired:
            theme.colors.info
        case .unknown:
            theme.colors.error
        }
    }

    /// The SF Symbol name for an icon representing this error in a badge or alert.
    /// Use with SwiftUI's `Image(systemName:)`.
    var systemIcon: String {
        switch self {
        case .awaitingLocalCredential:
            "hourglass"
        case .contactSeamSupport:
            "envelope.circle"
        case .unsupportedDevice:
            "iphone.slash"
        case .expired:
            "exclamationmark.circle"
        case .userInteractionRequired(let interaction):
            switch interaction {
            case .completeOtpAuthorization:
                "lock.slash"
            case .enableInternet:
                "cloud"
            case .enableBluetooth:
                "dot.radiowaves.right"
            case .grantBluetoothPermission:
                "dot.radiowaves.right"
            case .appRestartRequired:
                "togglepower"
            }
        case .unknown:
            "questionmark.square.dashed"
        }
    }

    /// A detailed, user-facing explanation of the error, suitable for alerts or inline error messages.
    var message: LocalizedStringKey {
        switch self {
        case .awaitingLocalCredential:
            "Your digital key is being prepared. Please wait a moment."
        case .contactSeamSupport:
            "An error occured with this key, please contact support."
        case .unsupportedDevice:
            "This device is not supported for this key. Please use a different device."
        case .expired:
            "Your digital key access has expired and can no longer be used."
        case .userInteractionRequired(let interaction):
            switch interaction {
            case .completeOtpAuthorization:
                "Please complete authorization by tapping the link that was sent to your email."
            case .enableInternet:
                "An internet connection is needed. Please connect to Wi‑Fi or mobile data."
            case .enableBluetooth:
                "Bluetooth is off. Please enable Bluetooth and/or tap \"Allow New Connections\" in Control Center or the Settings app."
            case .grantBluetoothPermission:
                "Please allow Bluetooth access for this app in the Settings app."
            case .appRestartRequired:
                "Please restart the app to resolve this issue."
            }
        case .unknown:
            "Sorry, something went wrong. Please try again."
        }
    }

    /// A short, actionable title for dialogs or sheets describing how the user can resolve the error.
    var title: LocalizedStringKey {
        switch self {
        case .awaitingLocalCredential:
            "Preparing Your Key"
        case .contactSeamSupport:
            "Contact Support"
        case .unsupportedDevice:
            "Unsupported Device"
        case .expired:
            "Your Key Has Expired"
        case .userInteractionRequired(let interaction):
            switch interaction {
            case .completeOtpAuthorization:
                "Finish Authorization"
            case .enableInternet:
                "Connect to Internet"
            case .enableBluetooth:
                "Turn On Bluetooth"
            case .grantBluetoothPermission:
                "Allow Bluetooth Access"
            case .appRestartRequired:
                "App Restart Required"
            }
        case .unknown:
            "Something Went Wrong"
        }
    }

    /// The recommended title for a primary action button that addresses the error, if applicable.
    /// Returns `nil` if no immediate user action is required.
    var primaryActionTitle: LocalizedStringKey? {
        switch self {
        case .userInteractionRequired(let interaction):
            switch interaction {
            case .completeOtpAuthorization:
                "Authorize"
            case .enableInternet, .enableBluetooth, .grantBluetoothPermission:
                "Open Settings"
            case .appRestartRequired:
                "Restart App Now"
            }
        case .awaitingLocalCredential, .contactSeamSupport, .unsupportedDevice, .expired, .unknown:
            nil
        }
    }

    /// A closure that performs the most relevant corrective action for this error, such as opening Settings or a verification link.
    /// This closure can be used directly in a SwiftUI `Button`.
    var primaryAction: () -> Void {
        switch self {
        case .userInteractionRequired(let interaction):
            switch interaction {
            case .completeOtpAuthorization(let otpUrl):
                return {
                    // Open the OTP authorization link in the browser
                    Task { @MainActor in
                        UIApplication.shared.open(otpUrl, options: [:], completionHandler: nil)
                    }
                }
            case .enableInternet:
                return {
                    Task { @MainActor in
                        // Open app settings so the user can enable internet
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                        }
                    }
                }
            case .enableBluetooth:
                return {
                    Task { @MainActor in
                        // Creating a CBCentralManager will prompt a system alert that leads to Bluetooth Settings.
                        CBCentralManager()
                    }
                }
            case .grantBluetoothPermission:
                return {
                    Task { @MainActor in
                        // Open app settings so the user can grant Bluetooth permission
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                        }
                    }
                }
            case .appRestartRequired:
                return {
                    // This will crash the app and trigger a restart...
                    let appRestartRequired: [Int] = []
                    _ = appRestartRequired.first!
                }
            }
        case .awaitingLocalCredential, .contactSeamSupport, .unsupportedDevice, .expired, .unknown:
            // No specific action available
            return { }
        }
    }
}

public extension SeamAccessCredential {
    /// Best‑effort mapping from ``provider`` to an asset name for branding.
    ///
    /// Falls back to `"SeamLogo"` when no mapping is available.
    var providerImageName: String {
        switch self.provider {
        case "salto_ks":
            return "salto_space"
        case "assa_abloy":
            return "assa_abloy"
        case "salto_space":
            return "salto_space"
        default:
            return "SeamLogo"
        }
    }
}

public extension SeamAccessCredential {
    /// Placeholder credential used while content is loading.
    ///
    /// - Note: The `id`/`location`/`name` fields contain sentinel values and should not
    ///   be displayed as real data.
    static let loading: SeamAccessCredential = .init(
        expiry: .distantFuture,
        location: "loading",
        id: "loading",
        name: "Loading",
        provider: nil,
        errors: []
    )
}
