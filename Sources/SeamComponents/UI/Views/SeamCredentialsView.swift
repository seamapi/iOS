/// # Seam Credentials UI Components
///
/// A collection of SwiftUI views and view models for displaying and selecting
/// mobile key credentials. Includes:
///
/// - ``SeamCredentialsViewModel``: an observable model for loading, searching,
///   and selecting credentials.
/// - ``SeamNoCredentialsView``: an empty‑state view with refresh support.
/// - ``SeamCredentialGrid`` and ``SeamCredentialTable``: grid and list displays.
///
/// ## Golden Path
///
/// The simplest way to integrate:
///
/// ```swift
/// SeamCredentialsView(viewModel: SeamCredentialsViewModel(seam: SeamService()))
/// ```
///
/// - Important: The underlying service keeps credentials up‑to‑date automatically.
///   Call ``SeamCredentialsViewModel/refreshCredentials()`` **optionally** (e.g., for
///   pull‑to‑refresh). Activation is triggered by the view model on first appearance.
///
/// - Requires: iOS 16+
///
/// ### Quick Start
/// 1. Create the view model:
///    ```swift
///    @StateObject var vm = SeamCredentialsViewModel(seam: SeamService())
///    ```
/// 2. Embed the grid or table view:
///    ```swift
///    SeamCredentialsView(viewModel: vm)
///    // or
///    SeamCredentialsTable(viewModel: vm)
///    ```
/// 3. (Optional) Customize cards by replacing contents of the grid/table.
import SwiftUI
import Combine


/// A main‑actor view model that drives credential listing and selection.
///
/// ``SeamCredentialsViewModel`` observes an injected ``SeamServiceProtocol`` to keep
/// credentials in sync, exposes live search via ``searchText``/``searchedCredentials``,
/// and tracks the current selection using ``selectedCredentialId``.
///
/// - Important: Credentials update automatically from the service; use
///   ``refreshCredentials()`` only to trigger a manual refresh (e.g., pull‑to‑refresh).
///
/// - Parameters:
///   - seam: The service instance used to observe credentials and activation state.
///
/// - SeeAlso: ``SeamAccessCredential``, ``SeamCredentialGrid``, ``SeamCredentialTable``
///
/// - Example:
/// ```swift
/// @StateObject var vm = SeamCredentialsViewModel(seam: SeamService())
/// SeamCredentialGrid(viewModel: vm)
/// ```
@MainActor
public final class SeamCredentialsViewModel: ObservableObject {
    // MARK: - Published state
    /// All available credentials, kept up‑to‑date automatically by the service.
    @Published public var credentials: [SeamAccessCredential]
    /// The currently selected credential identifier used to present unlock UI.
    /// Set to `nil` to dismiss the sheet.
    @Published public var selectedCredentialId: SeamAccessCredentialId? = nil
    /// The live search query. Updates ``searchedCredentials`` as the user types.
    @Published public var searchText: String = ""
    /// Reflects whether the underlying service is active. Updated on the main thread.
    @Published public private(set) var isActivated: Bool

    // MARK: - Dependency
    /// The injected service that exposes credentials and activation state.
    public let service: any SeamServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed
    /// Returns the filtered credentials based on ``searchText``.
    ///
    /// - Returns: The full list when the search text is empty; otherwise items
    ///   whose names match the query (case‑insensitive).
    public var searchedCredentials: [SeamAccessCredential] {
        if searchText.isEmpty {
            return credentials
        } else {
            return credentials.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // MARK: - Init / Deinit
    /// Creates a credentials view model.
    ///
    /// - Parameter service: A service conforming to ``SeamServiceProtocol`` used to
    ///   observe credentials, activation state, and perform manual refresh.
    public init(seam service: any SeamServiceProtocol = SeamServiceRegistry.auto) {
        self.service = service
        self.credentials = service.credentials
        self.isActivated = service.isActive

        // Observe service changes explicitly via protocol publishers
        service.credentialsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \SeamCredentialsViewModel.credentials, on: self)
            .store(in: &cancellables)

        service.isActivePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \SeamCredentialsViewModel.isActivated, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Intents
    /// Selects the given credential for unlock.
    ///
    /// - Parameter credential: The credential to select, or `nil` to clear the selection.
    public func select(credential: SeamAccessCredential?) {
        selectedCredentialId = credential?.id
    }

    /// Optionally triggers a manual refresh of credentials.
    ///
    /// Use for UI gestures like pull‑to‑refresh. Credentials also update automatically
    /// in the background via the service.
    public func refreshCredentials() async {
        _ = try? await service.refresh()
    }

    /// Handles view appearance.
    ///
    /// Activates the service on first appearance if needed and auto‑selects the sole
    /// credential when exactly one is present.
    ///
    /// - SeeAlso: ``SeamServiceProtocol/activate()``
    public func didAppear() {
        Task { [weak self] in
            guard let self else { return }
            if !self.isActivated {
                do { try await self.service.activate() } catch { /* optionally surface error */ }
                // state will also be updated via isActivePublisher
                if self.credentials.count == 1, let onlyCredentialId = self.credentials.first?.id {
                    self.selectedCredentialId = onlyCredentialId
                }
            }
        }
    }
}

/// A friendly empty‑state view with an optional loading mode and refresh action.
///
/// Displays a placeholder when there are no credentials and provides a "Refresh" button
/// wired to an async closure. When `isLoading` is `true` (or a refresh is in flight), a
/// lightweight loading state is shown instead.
///
/// - Parameters:
///   - isLoading: External loading flag (e.g., while activating) to show a spinner.
///   - refresh: An async closure invoked when the user taps **Refresh**.
///
/// - Example:
/// ```swift
/// SeamNoCredentialsView(isLoading: !viewModel.isActivated) {
///   await viewModel.refreshCredentials()
/// }
/// ```
public struct SeamNoCredentialsView: View {
    /// Async closure invoked to refresh the credentials list.
    public let refresh: () async -> Void
    /// External loading flag to control the loading presentation.
    public var isLoadingExternal: Bool

    @Environment(\.seamTheme) private var theme
    @State private var refreshTask: Task<Void, any Error>?

    public init(isLoading: Bool = false, refresh: @escaping () async -> Void) {
        self.isLoadingExternal = isLoading
        self.refresh = refresh
    }

    public var body: some View {
        VStack(alignment: .center) {
            let loading = isLoadingExternal || (refreshTask != nil)
            Spacer()
            if loading {
                // Optimistic, lightweight loading state
                Spacer()
                Image(systemName: "key.card")
                    .font(.system(size: 88))
                    .foregroundStyle(theme.colors.secondaryFill)
                    .padding(.top)

                ProgressView()
                    .scaleEffect(1.5)
                    .padding()

                Text("Fetching your mobile keys…")
                    .font(theme.fonts.title3)
                    .foregroundColor(theme.colors.secondaryText)
                Spacer()
                Spacer()
            } else {
                // Post-load empty state
                ZStack {
                    Image(systemName: "key.card")
                        .font(.system(size: 88))
                        .foregroundStyle(theme.colors.secondaryFill)
                    Image(systemName: "line.diagonal")
                        .font(.system(size: 120).weight(.medium))
                        .foregroundColor(Color(UIColor.systemBackground))
                    Image(systemName: "line.diagonal")
                        .font(.system(size: 110))
                        .foregroundStyle(theme.colors.secondaryFill)
                }
                .padding()

                Text("You have no mobile keys")
                    .font(theme.fonts.title3)
                    .foregroundColor(theme.colors.primaryText)

                Text("Please reach out to your property contact to make sure your mobile keys have been issued properly.")
                    .multilineTextAlignment(.center)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.secondaryText)
                    .padding(.vertical)
                Button(action: {
                    refreshTask = Task {
                        defer { refreshTask = nil }
                        await refresh()
                    }
                }) {
                    HStack(spacing: 8) {
                        if loading { ProgressView().controlSize(.small) }
                        Text(loading ? "Refreshing…" : "Refresh")
                    }
                }
                .disabled(loading)
                .buttonStyle(SeamIconButtonStyle(iconName: "arrow.clockwise"))
            }

            Spacer()
        }
        .background(theme.colors.primaryBackground)
        .padding()
    }
}

/// A stateless, scrollable grid of credential cards.
///
/// Shows shimmer placeholders when `isLoading` is `true`. Tapping a card invokes the
/// selection handler.
///
/// - Parameters:
///   - credentials: The credentials to display.
///   - isLoading: When `true`, shows placeholder rows instead of real data.
///   - onSelect: Called when a credential is tapped.
public struct SeamCredentialGrid: View {
    @Environment(\.seamTheme) private var theme
    public let credentials: [SeamAccessCredential]
    public let isLoading: Bool
    public var onSelect: ((SeamAccessCredential) -> Void)?

    private var _credentials: [SeamAccessCredential] {
        if isLoading {
            [.loading]
        } else {
            credentials
        }
    }

    public init(
        credentials: [SeamAccessCredential],
        isLoading: Bool = false,
        onSelect: ((SeamAccessCredential) -> Void)? = nil
    ) {
        self.credentials = credentials
        self.isLoading = isLoading
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(_credentials, id: \.id) { credential in
                    SeamKeyCardView(viewModel: SeamKeyCardViewModel(credential: credential))
                        .shimmer(active: isLoading)
                        .onTapGesture {
                            guard isLoading == false else { return }
                            onSelect?(credential)
                        }
                        .padding(.horizontal)
                }
            }
        }
        .background(theme.colors.primaryBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A stateless, searchable table of credentials.
///
/// Integrates with SwiftUI's `.searchable` via a bound `searchText`. Shows shimmer
/// placeholders when `isLoading` is `true`. Tapping a row invokes the selection handler.
///
/// - Parameters:
///   - credentials: The credentials to display (already filtered if desired).
///   - isLoading: When `true`, shows placeholder rows instead of real data.
///   - searchText: A binding to the search text.
///   - onSelect: Called when a credential is tapped.
public struct SeamCredentialTable: View {
    public let credentials: [SeamAccessCredential]
    @Binding public var searchText: String
    public let isLoading: Bool
    public var onSelect: ((SeamAccessCredential) -> Void)?

    @Environment(\.seamTheme) private var theme

    private var _credentials: [SeamAccessCredential] {
        if isLoading {
            [.loading]
        } else {
            credentials
        }
    }

    public init(
        credentials: [SeamAccessCredential],
        isLoading: Bool = false,
        searchText: Binding<String>,
        onSelect: ((SeamAccessCredential) -> Void)? = nil
    ) {
        self.credentials = credentials
        self.isLoading = isLoading
        self._searchText = searchText
        self.onSelect = onSelect
    }

    public var body: some View {
        List {
            ForEach(_credentials, id: \.id) { credential in
                Text(credential.name)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryText)
                    .shimmer(active: isLoading)
                    .onTapGesture {
                        guard isLoading == false else { return }
                        onSelect?(credential)
                    }
            }
        }
        .background(theme.colors.primaryBackground)
        .searchable(text: $searchText)
    }
}

/// Display styles for ``SeamCredentialsView``.
public enum SeamCredentialsViewStyle {
    /// A vertically scrolling grid of key cards.
    case grid
    /// A vertically scrolling list of searchable rows.
    case list
}

/// Coordinates credential presentation and unlock flow.
///
/// Owns a shared ``SeamCredentialsViewModel`` instance, renders either a grid or a table,
/// supports pull‑to‑refresh, and presents an unlock sheet when a credential is selected.
/// Automatically triggers activation on appearance when not already active.
///
/// - Parameters:
///   - viewModel: The shared credentials view model.
///   - style: The display style (grid or list). Defaults to ``SeamCredentialsViewStyle/grid``.
///
/// - SeeAlso: ``SeamUnlockCardView``, ``SeamUnlockCardViewModel``
///
/// - Example:
/// ```swift
/// SeamCredentialsView(viewModel: SeamCredentialsViewModel(seam: SeamService()), style: .grid)
/// ```
public struct SeamCredentialsView: View {
    @Environment(\.uiEventMonitor) private var uiEventMonitor
    @Environment(\.seamTheme) private var theme

    /// The view model driving the credentials UI and selection.
    @StateObject private var viewModel: SeamCredentialsViewModel
    let style: SeamCredentialsViewStyle

    /// Creates a new credentials view.
    ///
    /// - Parameters:
    ///   - viewModel: The shared view model to observe.
    ///   - style: The display style to use. Defaults to ``SeamCredentialsViewStyle/grid``.
    public init(viewModel: SeamCredentialsViewModel, style: SeamCredentialsViewStyle = .grid) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.style = style
    }

    public var body: some View {
        VStack {
            if viewModel.isActivated && viewModel.credentials.isEmpty {
                SeamNoCredentialsView(isLoading: !viewModel.isActivated, refresh: viewModel.refreshCredentials)
            } else {
                credentialsView
                    .refreshable { [weak viewModel] in
                        await viewModel?.refreshCredentials()
                    }
                    .sheet(item: Binding(
                        get: { viewModel.selectedCredentialId },
                        set: { viewModel.selectedCredentialId = $0 }
                    )) { credentialId in
                        let unlockVM = SeamUnlockCardViewModel(
                            credentialId: credentialId,
                            service: self.viewModel.service
                        )
                        if #available(iOS 16.0, *) {
                            SeamUnlockCardView(viewModel: unlockVM)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .presentationDetents([.large])
                                .background(theme.unlockCard.cardBackground ?? theme.colors.primaryBackground)
                        } else {
                            SeamUnlockCardView(viewModel: unlockVM)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(theme.unlockCard.cardBackground ?? theme.colors.primaryBackground)                        }
                    }
            }
        }
        // Auto‑activate on first appearance and auto‑select the sole credential.
        .onAppear(perform: viewModel.didAppear)
        .monitorScreen(appeared: .credentialsViewAppeared, disappeared: .credentialsViewDisappeared)
    }

    public var credentialsView: some View {
        VStack {
            if style == .grid {
                SeamCredentialGrid(
                    credentials: viewModel.credentials,
                    isLoading: !viewModel.isActivated,
                    onSelect: { credential in
                        viewModel.select(credential: credential)
                    }
                )
            } else {
                SeamCredentialTable(
                    credentials: viewModel.searchedCredentials,
                    isLoading: !viewModel.isActivated,
                    searchText: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.searchText = $0 }
                    ),
                    onSelect: { credential in
                        viewModel.select(credential: credential)
                    }
                )
            }
        }
    }
}


#if DEBUG
#Preview("Grid View") {
    SeamCredentialsView(viewModel: SeamCredentialsViewModel(seam: PreviewSeamService.shared))
        .environment(\.seamTheme, SeamTheme.previewTheme)
        .environment(\.uiEventMonitor, UIEventMonitor.disabled)
}

#Preview("Table View") {
    SeamCredentialsView(viewModel: SeamCredentialsViewModel(seam: PreviewSeamService.shared),
                        style: .list)
        .environment(\.seamTheme, SeamTheme.previewTheme)
        .environment(\.uiEventMonitor, UIEventMonitor.disabled)
}

// Pure grid/table previews
#Preview("Pure Grid") {
    SeamCredentialGrid(
        credentials: SeamAccessCredential.credentials,
        onSelect: { _ in }
    )
    .environment(\.seamTheme, SeamTheme.previewTheme)
}

#Preview("Pure Table") {
    let vm = SeamCredentialsViewModel(seam: PreviewSeamService.shared)
    SeamCredentialTable(
        credentials: vm.searchedCredentials,
        searchText: .constant(""),
        onSelect: { _ in }
    )
    .environment(\.seamTheme, SeamTheme.previewTheme)
}
#endif
