import Foundation
import Combine

// MARK: - Seam Service Protocol

/// A main‑actor service interface that mirrors core Seam SDK state and commands for the UI.
///
/// Conforming types adapt `Seam.shared` into UI‑friendly models (``SeamAccessCredential``)
/// and Combine publishers compatible with iOS 16 protocol constraints.
///
/// - Published state (read‑only): ``credentials``, ``isActive``
/// - Publishers: ``credentialsPublisher``, ``isActivePublisher``
/// - Commands: ``initialize(clientSessionToken:)``, ``activate()``, ``refresh()``,
///   ``unlock(using:timeout:)``, ``deactivate(deintegrate:)``
///
/// ### Usage
/// ```swift
/// final class MyViewModel: ObservableObject {
///     @MainActor @Published var rows: [SeamAccessCredential] = []
///     private let seam: any SeamServiceProtocol
///
///     init(seam: SeamServiceProtocol) {
///         self.seam = seam
///         // Drive UI from the published credentials
///         rows = seam.credentials
///     }
/// }
/// ```
///
/// - Important: All requirements execute on the **main actor** to keep UI updates
///   consistent with SDK emissions.

@MainActor
public protocol SeamServiceProtocol: AnyObject, ObservableObject {
    /// Current list of credentials exposed as UI models.
    /// Mirrors `Seam.shared.credentials` and updates on the main thread.
    var credentials: [SeamAccessCredential] { get }
    /// Whether the SDK is currently active (`activate()` has succeeded).
    var isActive: Bool { get }
    /// Fine‑grained publisher that emits ``isActive`` changes.
    var isActivePublisher: AnyPublisher<Bool, Never> { get }
    /// Fine‑grained publisher that emits ``credentials`` snapshots.
    var credentialsPublisher: AnyPublisher<[SeamAccessCredential], Never> { get }

    /// Initializes the SDK with a client session token.
    ///
    /// - Parameter clientSessionToken: A non‑empty token string. Pass the value obtained after user login.
    /// - Throws: `SeamError.invalidClientSessionToken` if the token is missing or malformed;
    ///   `SeamError.deactivationInProgress` if a deactivation is running; `SeamError.alreadyInitialized`
    ///   if the SDK was already initialized.
    func initialize(clientSessionToken: String) throws
    /// Activates the SDK to begin synchronization and processing.
    ///
    /// - Throws: `SeamError.initializationRequired` if `initialize` wasn’t called;
    ///   `SeamError.deactivationInProgress` if a deactivation is running.
    func activate() async throws
    /// Manually refreshes credentials and returns the latest snapshot.
    ///
    /// - Note: The UI is kept up‑to‑date automatically via ``credentials``. Call this to
    ///   drive explicit refresh UI (e.g., pull‑to‑refresh).
    /// - Throws: `SeamError.initializationRequired`, `SeamError.deactivationInProgress`.
    @discardableResult
    func refresh() async throws -> [SeamAccessCredential]
    /// Starts an unlock operation and returns a stream of UI events.
    ///
    /// - Parameters:
    ///   - credentialId: The identifier of the credential to use for unlocking.
    ///   - timeout: Maximum time in seconds to wait before the attempt times out.
    /// - Returns: A publisher emitting ``SeamAccessUnlockEvent`` values (`Never` failure).
    /// - Throws: `SeamError.initializationRequired`, `SeamError.invalidCredentialId`,
    ///   `SeamError.integrationNotFound`, or `SeamError.credentialErrors(_:)` when preconditions
    ///   aren’t met prior to starting the operation.
    func unlock(using credentialId: String, timeout: TimeInterval) throws -> AnyPublisher<SeamAccessUnlockEvent, Never>
    /// Deactivates the SDK and optionally deintegrates the device.
    /// - Parameter deintegrate: When `true`, performs full deintegration; otherwise retains endpoints.
    func deactivate(deintegrate: Bool) async
}
