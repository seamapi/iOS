import Foundation
import Combine
/**
 Stable, observable proxy to the current registry service.

 This type mirrors the state and publishers of the active service (``SeamServiceRegistry/live``
 when non‑`nil`, otherwise ``SeamServiceRegistry/mock``). When the registry changes,
 the proxy seamlessly re‑attaches and begins mirroring the new source.

 - SeeAlso: ``SeamServiceRegistry``
 */
@MainActor
public final class AutoSeamService: SeamServiceProtocol {
    // Singleton instance used by the registry convenience accessor
    public static let shared = AutoSeamService()

    // MARK: - Published state mirrored from the current underlying service
    /// Latest credentials mirrored from the active service. Updated on the main thread.
    @Published public private(set) var credentials: [SeamAccessCredential] = []
    /// Whether the active service is currently running (mirrored).
    @Published public private(set) var isActive: Bool = false

    /// A publisher of ``isActive`` changes, exposed as `AnyPublisher` for UI consumption.
    public var isActivePublisher: AnyPublisher<Bool, Never> {
        $isActive.eraseToAnyPublisher()
    }

    /// A publisher of credential arrays for list rendering and bindings.
    public var credentialsPublisher: AnyPublisher<[SeamAccessCredential], Never> {
        $credentials.eraseToAnyPublisher()
    }

    private var cancellables: Set<AnyCancellable> = []

    /// Creates the singleton proxy and attaches to the current registry service.
    private init() {
        // Attach to whichever service is available at startup.
        observeCurrentService()
    }

    /// The preferred service: ``SeamServiceRegistry/live`` when set, else ``SeamServiceRegistry/mock``.
    private var currentService: any SeamServiceProtocol {
        SeamServiceRegistry.live ?? SeamServiceRegistry.mock
    }

    /// Re‑wires subscriptions to the current service and seeds mirrored state.
    private func observeCurrentService() {
        cancellables.removeAll()

        // Seed immediate state
        credentials = currentService.credentials
        isActive = currentService.isActive

        // Mirror changes going forward
        currentService.credentialsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.credentials = $0 }
            .store(in: &cancellables)

        currentService.isActivePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.isActive = $0 }
            .store(in: &cancellables)

        print("SeamComponents AutoSeamService - INFO: Using SeamServiceRegistry.\(SeamServiceRegistry.live != nil ? "live" : "mock") SeamSDK service.")
    }

    /**
     Re‑attaches the proxy after the registry changed.

     Called automatically by the registry when ``live`` or ``mock`` is updated.
     You may call it manually if you mutate underlying services in place.
     */
    public func refreshRegistry() {
        observeCurrentService()
    }

    /**
     Forwards initialization to the active service.

     - SeeAlso: SeamServiceProtocol ``SeamServiceProtocol/initialize(clientSessionToken:)``
     */
    public func initialize(clientSessionToken: String) throws {
        try currentService.initialize(clientSessionToken: clientSessionToken)
    }

    /**
     Forwards activation to the active service.

     - SeeAlso: SeamServiceProtocol ``SeamServiceProtocol/activate()``
     */
    public func activate() async throws {
        try await currentService.activate()
    }

    /**
     Requests a manual credential refresh from the active service.

     - SeeAlso: SeamServiceProtocol ``SeamServiceProtocol/refresh()``
     */
    @discardableResult
    public func refresh() async throws -> [SeamAccessCredential] {
        try await currentService.refresh()
    }

    /**
     Starts an unlock flow via the active service and returns its event stream.

     - SeeAlso: SeamServiceProtocol ``SeamServiceProtocol/unlock(using:timeout:)``
     */
    public func unlock(using credentialId: String, timeout: TimeInterval) throws -> AnyPublisher<SeamAccessUnlockEvent, Never> {
        try currentService.unlock(using: credentialId, timeout: timeout)
    }

    /**
     Forwards deactivation to the active service.

     - SeeAlso: SeamServiceProtocol ``SeamServiceProtocol/deactivate(deintegrate:)``
     */
    public func deactivate(deintegrate: Bool) async {
        await currentService.deactivate(deintegrate: deintegrate)
    }
}
