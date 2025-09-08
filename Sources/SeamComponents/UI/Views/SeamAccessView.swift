import SwiftUI
import Combine

/// A view model that manages Seam activation and exposes state for SwiftUI.
///
/// `SeamAccessViewModel` coordinates activation via an injected ``SeamServiceProtocol``
/// and publishes UI-ready state (e.g., ``isActive`` and ``isActivating``). Errors from
/// activation attempts are captured as user-visible text in ``activationError``.
///
/// - Important: This type is annotated with `@MainActor`, ensuring updates to published
///   properties occur on the main thread.
///
/// - SeeAlso: ``SeamAccessView``
///
/// - Example:
/// ```swift
/// let viewModel = SeamAccessViewModel()
/// viewModel.activate() // starts an async activation Task
/// ```
@MainActor
public final class SeamAccessViewModel: ObservableObject {
    // MARK: - Published/UI state
    /// Indicates whether the Seam service is currently active.
    /// Mirrors the underlying service state and updates on the main thread.
    @Published public private(set) var isActive: Bool
    /// `true` while an activation Task is in progress; otherwise `false`.
    @Published public private(set) var isActivating: Bool = false
    /// The latest activation error message suitable for display, if any.
    /// Cleared on successful activation or when a new attempt starts.
    @Published public var activationError: String?

    /// The current activation Task if one is running. Cancel this to abort activation.
    public var activationTask: Task<Void, any Error>?

    // MARK: - Dependency
    /// The injected service abstraction used to perform activation and expose state.
    public let service: any SeamServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init / Deinit
    /// Creates a new view model.
    ///
    /// - Parameter service: A service that implements ``SeamServiceProtocol``.
    ///   Defaults to a live ``SeamService`` instance when the Seam SDK is present.
    ///   Otherwise a ``PreviewSeamService`` is used.
    public init(service: any SeamServiceProtocol = SeamServiceRegistry.auto) {
        self.service = service
        self.isActive = service.isActive

        // Observe explicit isActive changes from the service (protocol-friendly for iOS 16)
        service.isActivePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \SeamAccessViewModel.isActive, on: self)
            .store(in: &cancellables)
    }

    // MARK: - API
    /// Starts the asynchronous activation process.
    ///
    /// Launches a `Task` that calls `service.activate()` and updates ``isActive`` on success.
    /// Errors are captured to ``activationError`` instead of being thrown.
    ///
    /// - Important: Calling this method while ``isActivating`` is `true` is a no-op.
    ///   Cancel ``activationTask`` to abort an in-flight attempt.
    ///
    /// - SeeAlso: ``SeamServiceProtocol/activate()``
    ///
    /// - Example:
    /// ```swift
    /// let vm = SeamAccessViewModel()
    /// vm.activate()
    /// ```
    public func activate() {
        guard !isActivating else { return }
        activationTask = Task {
            isActivating = true
            defer {
                isActivating = false
                activationTask = nil
            }
            do {
                try await service.activate()
                // Ensure state reflects latest
                isActive = service.isActive
            } catch {
                activationError = "\(error)"
            }
        }
    }
}

/// A SwiftUI wrapper that triggers Seam activation and displays credentials.
///
/// ``SeamAccessView`` injects a ``SeamAccessViewModel`` and delegates credential presentation
/// to ``SeamCredentialsView``. On appearance, it automatically triggers activation when needed.
///
/// - Features:
///   - Automatically activates on first appearance if not already active.
///   - Delegates UI for listing credentials to ``SeamCredentialsView``.
///
/// - Customization:
///   Provide a custom view model to integrate mocks or alternative services:
///   ```swift
///   SeamAccessView(viewModel: SeamAccessViewModel(service: MockSeamService()))
///   ```
///
/// - Note: Error presentation and loading indicators (if any) are expected to be
///   implemented by the delegated views (e.g., ``SeamCredentialsView``) or by
///   wrapping containers.
public struct SeamAccessView: View {
    @Environment(\.seamTheme) private var theme
    @Environment(\.uiEventMonitor) private var uiEventMonitor

    /// The view model driving activation and unlocking logic.
    /// Stored as a `@StateObject` so the instance lifecycle is owned by the view.
    @StateObject private var viewModel: SeamAccessViewModel

    /// Creates a new ``SeamAccessView``.
    ///
    /// - Parameter viewModel: The view model to use. Defaults to a new ``SeamAccessViewModel``.
    public init(viewModel: SeamAccessViewModel = SeamAccessViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack {
            SeamCredentialsView(viewModel: .init(seam: viewModel.service))
        }
        .background(theme.colors.primaryBackground)
        /// Automatically triggers activation when the view appears and the service
        /// is not yet active and no activation is currently running.
        .onAppear {
            if !viewModel.isActive && !viewModel.isActivating {
                viewModel.activate()
            }
        }
        .monitorScreen(appeared: .accessViewAppeared, disappeared: .accessViewDisappeared)
    }
}

#if DEBUG
#Preview {
    SeamAccessView(viewModel: SeamAccessViewModel(service: PreviewSeamService.shared))
        .environment(\.seamTheme, SeamTheme.previewTheme)
        .environment(\.uiEventMonitor, UIEventMonitor.disabled)
}
#endif
