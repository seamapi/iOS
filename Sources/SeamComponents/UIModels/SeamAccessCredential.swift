import Foundation
import SwiftUI

/// UI-layer events emitted during an unlock operation.
///
/// ``SeamAccessUnlockEvent`` mirrors the SDK's `SeamUnlockEvent` so views and view models
/// can react to progress, success, and failure without depending directly on the SDK type.
/// Use these events to drive state machines, animations, and user feedback.
///
/// - SeeAlso: `SeamUnlockEvent`
public enum SeamAccessUnlockEvent: Sendable, Equatable, Hashable {
    /// The unlock process has started (initial scanning/probing).
    case launched
    /// Access was granted by the lock hardware (success).
    case grantedAccess
    /// The operation timed out without receiving a success signal.
    case timedOut
    /// Connection or protocol negotiation failed, optionally with a debug message.
    case connectionFailed(debugDescription: String?)
}


/// Errors related to a Seam access credential’s state or prerequisites.
///
/// Use these cases to drive UI badges, alerts, or flows that
/// indicate why a credential cannot be used to unlock.
/// These mirror the `SeamCredentialError` cases from the Seam SDK, providing a UI-focused representation.
public enum SeamAccessCredentialError: Sendable, Equatable, Hashable {
    /// The local credential is still being generated or fetched.
    case awaitingLocalCredential
    /// The credential’s validity period has passed.
    case expired
    /// Configuration error requiring developer attention.
    case contactSeamSupport
    /// The current device is not supported.
    case unsupportedDevice
    /// User action is required to proceed (e.g., enable Bluetooth, complete OTP).
    case userInteractionRequired(RequiredUserInteraction)
    /// An unknown error occurred. Retry or contact support.
    case unknown

    /// Specific user interactions required to enable credential use.
    public enum RequiredUserInteraction: Sendable, Equatable, Hashable {
        /// User must complete OTP authorization via the provided URL.
        case completeOtpAuthorization(otpUrl: URL)
        /// User must enable internet connectivity.
        case enableInternet
        /// User must enable Bluetooth on the device.
        case enableBluetooth
        /// User must grant Bluetooth permission for the app.
        case grantBluetoothPermission
        /// User must restart the app to recover from an error.
        case appRestartRequired
    }
}

// MARK: Access Credential

/// The unique identifier type for a Seam access credential.
public typealias SeamAccessCredentialId = String

/// Adopt `Identifiable` for seamless use in SwiftUI lists and bindings.
extension SeamAccessCredentialId: @retroactive Identifiable {
    public var id: Self { self }
}

/// A UI-facing snapshot of an access credential used for display, selection, and unlock.
///
/// ``SeamAccessCredential`` mirrors key fields from the SDK's credential model and adds
/// presentation conveniences used by InstantKeys (e.g., provider branding). Values are
/// intended to be read-only snapshots synchronized from the SDK layer.
///
/// - Important: The presence of items in ``errors`` indicates the credential cannot be used
///   to unlock until those issues are resolved.
///
/// ### Example
/// ```swift
/// let cred = SeamAccessCredential(
///   expiry: Date().addingTimeInterval(3600),
///   location: "Lobby",
///   id: "abc123",
///   name: "Main Door",
///   provider: "salto_space",
///   errors: []
/// )
/// ```
public struct SeamAccessCredential: Sendable, Identifiable, Equatable, Hashable {
    /// When the credential expires, if available. `nil` means no known expiry.
    public var expiry: Date?
    /// Displayable location or context for the credential (e.g., building/area).
    public var location: String

    /// Stable identifier for this credential (also used for `Identifiable.id`).
    public var id: SeamAccessCredentialId
    /// Human‑friendly label shown in lists and detail views.
    public var name: String
    /// Optional card/credential number when applicable.
    public var cardNumber: String?
    /// Optional access code when applicable.
    public var code: String?
    /// Provider/integration identifier (e.g., `"salto_space"`).
    public var provider: String?
    /// Current issues preventing use. Empty array means the credential is ready.
    public var errors: [SeamAccessCredentialError]

    /// Creates an access credential snapshot.
    ///
    /// - Parameters:
    ///   - expiry: Optional expiration date.
    ///   - location: Display location/context.
    ///   - id: Unique identifier.
    ///   - name: Display name.
    ///   - provider: Provider/integration key.
    ///   - errors: Current credential errors.
    ///   - cardNumber: Optional card number.
    ///   - code: Optional access code.
    public init(expiry: Date?, location: String, id: String, name: String, provider: String?, errors: [SeamAccessCredentialError],
                cardNumber: String? = nil, code: String? = nil) {
        self.expiry = expiry
        self.location = location
        self.id = id
        self.name = name
        self.cardNumber = cardNumber
        self.code = code
        self.provider = provider
        self.errors = errors
    }
}
