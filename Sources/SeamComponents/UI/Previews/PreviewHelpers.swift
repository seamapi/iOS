/**
 Preview-only helpers and mock services for Xcode Previews & demo builds.

 - Important: This file is compiled only in DEBUG/Preview configurations (`#if DEBUG`).
 - SeeAlso: `SeamServiceProtocol`, `SeamService`
 */
// MARK: - Preview Helpers

import SwiftUI
import Combine

/// A main‑actor mock service for previews/tests that conforms to ``SeamServiceProtocol``.
///
/// Publishes in‑memory credentials and simulates unlock events. Use this in Xcode
/// Previews to drive UI without contacting the real SDK.
@MainActor
final class PreviewSeamService: SeamServiceProtocol {
    /// Current preview credentials.
    @Published private(set) var credentials: [SeamAccessCredential]
    /// Whether the mock service is considered active.
    @Published private(set) var isActive: Bool

    /// Emits ``isActive`` changes.
    var isActivePublisher: AnyPublisher<Bool, Never> { $isActive.eraseToAnyPublisher() }
    /// Emits credential list snapshots.
    var credentialsPublisher: AnyPublisher<[SeamAccessCredential], Never> { $credentials.eraseToAnyPublisher() }

    /// Creates a preview service with the given seed data.
    init(credentials: [SeamAccessCredential], isActive: Bool = true) {
        self.credentials = credentials
        self.isActive = isActive
    }

    /// No‑op for previews.
    func initialize(clientSessionToken: String) throws {}
    /// Sets ``isActive`` to `true`.
    func activate() async throws { isActive = true }
    /// Simulates a network refresh with a short delay and returns current credentials.
    @discardableResult
    func refresh() async throws -> [SeamAccessCredential] {
        try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        return credentials
    }
    /// Simulates an unlock: emits `.launched` then `.grantedAccess`. Never fails.
    func unlock(using credentialId: String, timeout: TimeInterval) throws -> AnyPublisher<SeamAccessUnlockEvent, Never> {
        Just(SeamAccessUnlockEvent.launched)
            .append(Just(.grantedAccess).delay(for: .seconds(0.5), scheduler: DispatchQueue.main))
            .eraseToAnyPublisher()
    }
    /// Sets ``isActive`` to `false`.
    func deactivate(deintegrate: Bool) async { isActive = false }
}

extension PreviewSeamService {
    /// Shared preview instance seeded with sample credentials.
    static var shared: PreviewSeamService {
#if DEBUG
        .init(credentials: SeamAccessCredential.credentials)
#else
        .init(credentials: [])
#endif
    }
}

// MARK: - Debug-only mocks & sample data
#if DEBUG

/// Preview convenience to bypass localization linting/tests.
/// Returns the same string without looking up a localized value.
extension String {
    /// Returns `self` as-is, useful for preview/dummy strings.
    var excludeLocalization: String { String(self) }
}

/// Preview theming convenience.
extension SeamTheme {
    /// A simple theme used in previews. Override to demonstrate custom branding.
    public static var previewTheme: SeamTheme {
//                .init()
        DemoSeamTheme.theme
    }
}

/// Minimal placeholder view used in previews.
struct SeamUnlockMockView: View {
    var body: some View {
        Text("Preview View!")
    }
}

/// Sample credentials used for previews and visual testing.
public extension SeamAccessCredential {
    /// Shows ".awaitingLocalCredential" state.
    static let awaitingLocalCredential: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.distantFuture,
        location: "San Diego Marriott Del Mar",
        id: "awaitingLocalCredential",
        name: "Mock Awaiting",
        provider: "assa_abloy",
        errors: [.awaitingLocalCredential]
    )

    /// Shows a `.userInteractionRequired(.completeOtpAuthorization)` state.
    static let completeOtpAuthorization: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.distantFuture,
        location: "San Diego Marriott Del Mar",
        id: "completeOtpAuthorization",
        name: "Mock OTP Required",
        provider: "assa_abloy",
        errors: [.userInteractionRequired(.completeOtpAuthorization(otpUrl: URL(string: "https://www.seam.co")!))]
    )

    /// Shows a `.userInteractionRequired(.enableBluetooth)` state.
    static let enableBluetooth: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.distantFuture,
        location: "San Diego Marriott Del Mar",
        id: "enableBluetooth",
        name: "Mock Bluetooth Off",
        provider: "assa_abloy",
        errors: [.userInteractionRequired(.enableBluetooth)]
    )

    /// Shows a `.userInteractionRequired(.enableInternet)` state.
    static let enableInternet: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.distantFuture,
        location: "San Diego Marriott Del Mar",
        id: "enableInternet",
        name: "Mock Internet Off",
        provider: "assa_abloy",
        errors: [.userInteractionRequired(.enableInternet)]
    )

    /// Shows a `.userInteractionRequired(.grantBluetoothPermission)` state.
    static let grantBluetoothPermission: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.distantFuture,
        location: "San Diego Marriott Del Mar",
        id: "grantBluetoothPermission",
        name: "Mock Bluetooth Permission",
        provider: "assa_abloy",
        errors: [.userInteractionRequired(.grantBluetoothPermission)]
    )

    /// Shows an `.unknown` error state.
    static let unknown: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.distantFuture,
        location: "San Diego Marriott Del Mar",
        id: "unknownError",
        name: "Mock Unknown Error",
        provider: "assa_abloy",
        errors: [.unknown]
    )

    /// Shows an `.expired` error state.
    static let expired: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.now - (60 * 60 * 24),
        location: "San Diego Marriott Del Mar",
        id: "expired",
        name: "Mock Expired",
        provider: "assa_abloy",
        errors: [.expired]
    )

    /// Shows a `.userInteractionRequired(.appRestartRequired)` state.
    static let appRestartRequired: SeamAccessCredential = SeamAccessCredential(
        expiry: Date.distantFuture,
        location: "San Diego Marriott Del Mar",
        id: "appRestartRequired",
        name: "Mock App Restart Required",
        provider: "assa_abloy",
        errors: [.userInteractionRequired(.appRestartRequired)]
    )

    /// A small set of valid-looking credentials for general previews.
    static let credentials = [
        SeamAccessCredential(expiry: Date.distantFuture,
                             location: "San Diego Marriott Del Mar",
                             id: "mock1",
                             name: "Mock Card 1",
                             provider: "assa_abloy",
                             errors: [],
                             cardNumber: nil,
                             code: nil),
        SeamAccessCredential(expiry: Date.now - (60 * 60 * 24),
                             location: "Marriot at Half Moon Bay",
                             id: "mock2",
                             name: "Mock Card 2",
                             provider: "assa_abloy",
                             errors: [],
                             cardNumber: nil,
                             code: nil),
    ]

    /// A showcase of credentials spanning common error states.
    static let errorCredentials: [SeamAccessCredential] = [
        awaitingLocalCredential,
        completeOtpAuthorization,
        enableBluetooth,
        enableInternet,
        grantBluetoothPermission,
        unknown,
        expired,
        appRestartRequired,
    ]
}

#endif
