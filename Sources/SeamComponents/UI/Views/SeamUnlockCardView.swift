import SwiftUI
import Combine


/// A main-actor view model that orchestrates the unlock flow for a single credential.
///
/// ``SeamUnlockCardViewModel`` observes credentials from an injected ``SeamServiceProtocol``,
/// exposes a UI-ready state machine via ``state``, and starts/cancels unlock attempts.
/// It also surfaces OTP web authorization via ``otpWebViewUrl`` when required.
///
/// - Important: This type is annotated with `@MainActor` to ensure UI updates
///   occur on the main thread.
///
/// - SeeAlso: ``SeamUnlockCardView``
///
/// - Example:
/// ```swift
/// @StateObject var vm = SeamUnlockCardViewModel(credentialId: id, service: SeamService())
/// vm.startUnlock()
/// ```
@MainActor
public final class SeamUnlockCardViewModel: ObservableObject {
    /// Distinct UI states for the unlock card.
    public enum UnlockCardState: Equatable {
        /// No active operation; ready to begin.
        case idle
        /// Attempting to connect / present credentials to the lock.
        case connecting
        /// Unlock succeeded.
        case success
        /// Unlock failed with a user-visible message.
        /// - Parameter message: Human-readable explanation of the failure.
        case failure(String)
        /// A credential-level error is blocking unlock.
        /// - Parameter error: The highest-priority ``SeamAccessCredentialError``.
        case error(SeamAccessCredentialError)
    }

    // MARK: - Published state
    /// Internal state for the view model's state machine.
    /// Combined with the current credential's first error in ``state``.
    @Published var _state: UnlockCardState = .idle
    /// When non-`nil`, an OTP web authorization is required and should be presented.
    @Published public var otpWebViewUrl: URL? = nil
    /// Snapshot of the credential referenced by ``credentialId``.
    /// Updated automatically via the service publisher.
    @Published private(set) var currentCredential: SeamAccessCredential?

    /// Effective UI state combining internal state with any leading credential error.
    /// If the current credential has errors, ``UnlockCardState/error(_:)`` takes precedence.
    public var state: UnlockCardState {
        if let error = currentCredential?.errors.first { return .error(error) }
        return _state
    }

    /// The current in-flight unlock task, if any. Cancel to abort the attempt.
    public var unlockTask: Task<(), any Error>?

    /// `true` while actively connecting/presenting to the lock.
    public var isUnlocking: Bool { if case .connecting = state { return true } else { return false } }

    /// A short UI title describing the current phase (e.g., "Tap to unlock", "Connecting…").
    public var phaseTitle: String {
        switch state {
        case .idle:       return "Tap to unlock"
        case .connecting: return "Connecting…"
        default:          return ""
        }
    }

    /// Convenience flag indicating whether OTP web authorization should be shown.
    public var otpWebAuthRequired: Bool { otpWebViewUrl != nil }

    /// The identifier of the credential to unlock.
    private let credentialId: SeamAccessCredentialId
    /// Service responsible for credential observation and performing unlock.
    private let service: any SeamServiceProtocol
    /// Combine subscriptions retained by the view model.
    private var cancellables = Set<AnyCancellable>()

    /// Creates a view model for the given credential.
    ///
    /// Seeds `currentCredential` from the service snapshot and subscribes to
    /// ``SeamServiceProtocol/credentialsPublisher`` to receive updates on the main thread.
    ///
    /// - Parameters:
    ///   - credentialId: The identifier of the credential to unlock.
    ///   - service: A service wrapper that provides state and unlock commands.
    public init(credentialId: SeamAccessCredentialId, service: any SeamServiceProtocol) {
        self.credentialId = credentialId
        self.service = service

        // Seed from current snapshot
        self.currentCredential = service.credentials.first { $0.id == credentialId }

        // Observe credential list changes via the service publisher
        service.credentialsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] creds in
                self?.currentCredential = creds.first { $0.id == credentialId }
            }
            .store(in: &cancellables)

        // Prepare haptics so that it fires without delay when unlock is tapped.
        SeamHaptics.prepare()
    }

    /// Cancels any in-flight unlock task when the view model is deallocated.
    deinit {
        unlockTask?.cancel()
    }

    /// Starts or manages the unlock flow.
    ///
    /// - Behavior:
    ///   - If already ``UnlockCardState/connecting``, calls ``cancelUnlock()``.
    ///   - If in ``UnlockCardState/success``, ``UnlockCardState/failure(_:)``, or ``UnlockCardState/error(_:)``, resets to ``UnlockCardState/idle``.
    ///   - Otherwise, resolves the credential, transitions to ``UnlockCardState/connecting``,
    ///     and consumes unlock events from ``SeamServiceProtocol/unlock(using:timeout:)``.
    ///
    /// - Event Mapping:
    ///   - `.launched` → `.connecting`
    ///   - `.grantedAccess` → `.success`
    ///   - `.timedOut` → `.idle`
    ///   - `.connectionFailed(debugDescription:)` → `.failure(debugDescription ?? "unknown")`
    ///
    /// - Error Handling: Any thrown error sets ``UnlockCardState/failure(_:)`` with its localized description.
    ///
    /// - Note: The returned task is stored in ``unlockTask`` for cancellation.
    public func startUnlock() {
        switch state {
        case .connecting:
            cancelUnlock()
        case .success, .failure, .error:
            reset()
        case .idle:
            guard let credential = currentCredential ?? service.credentials.first(where: { $0.id == credentialId }) else {
                _state = .failure("Credential unavailable")
                return
            }
            _state = .connecting
            unlockTask = Task {
                do {
                    // Consume unlock events
                    for await event in try service.unlock(using: credential.id, timeout: 10).values {
                        await MainActor.run {
                            switch event {
                            case .launched:
                                SeamHaptics.info()
                                self._state = .connecting
                            case .grantedAccess:
                                SeamHaptics.success()
                                self._state = .success
                            case .timedOut:
                                SeamHaptics.warning()
                                self._state = .idle
                            case .connectionFailed(debugDescription: let debugDescription):
                                SeamHaptics.error()
                                self._state = .failure(debugDescription ?? "unknown")
                            }
                        }
                    }
                } catch {
                    SeamHaptics.error()
                    await MainActor.run { self._state = .failure(error.localizedDescription) }
                }
            }
        }
    }

    /// Cancels the current unlock attempt (if any) and resets to ``UnlockCardState/idle``.
    public func cancelUnlock() {
        unlockTask?.cancel()
        reset()
    }

    /// Resets the state machine back to ``UnlockCardState/idle``.
    public func reset() { _state = .idle }

    /// Produces a primary action closure for a credential error.
    ///
    /// If the error requires OTP authorization, sets ``otpWebViewUrl`` so the caller can present
    /// a web view. Otherwise, forwards to the error's built-in ``SeamAccessCredentialError/primaryAction``.
    ///
    /// - Parameter error: The credential error to resolve.
    /// - Returns: A closure suitable for binding to a button action.
    public func errorAction(error: SeamAccessCredentialError) -> () -> Void {
        return { [weak self] in
            if case let .userInteractionRequired(requiredInteraction) = error,
               case let .completeOtpAuthorization(otpUrl) = requiredInteraction {
                self?.otpWebViewUrl = otpUrl
            } else {
                error.primaryAction()
            }
        }
    }
}

/// # SeamUnlockCardView
///
/// A key card style digital unlock card that manages and displays the full unlock workflow, animated progress, and error/status overlays with accessibility and customization support.
///
/// - Integrates with the SeamComponents and SeamSDK for credential management and unlock.
/// - Highly composable—use as a modal, in lists/grids, or as a standalone view.
/// - Supports fully customizable error/status overlays via ``SeamAccessCredentialErrorStyle``.
/// - Accessible by design: dynamic type, VoiceOver, high-contrast.
/// - Requires: iOS 16+, ObservableObject + Combine.
///
/// ## Usage
/// 1. Create your view model:
///    ```swift
///    @StateObject var vm = SeamUnlockCardViewModel(
///        credentialId: myCredentialId,
///        service: SeamService()
///    )
///    ```
/// 2. Present the unlock card:
///    ```swift
///    SeamUnlockCardView(viewModel: vm)
///        .frame(width: 300, height: 400)
///    ```
///
/// ## Customizing Error Appearance
/// Pass a custom ``SeamAccessCredentialErrorStyle`` to the ``errorStyle`` parameter of ``SeamUnlockCardView`` to control icon, color, and messages for error/status overlays.
///
/// ## Topics
/// - ``SeamUnlockCardViewModel``
/// - ``SeamAccessCredentialErrorStyle``
///
/// - SeeAlso: ``SeamKeyCardView``, ``SeamCredentialsView``
///
public struct SeamUnlockCardView: View {
    @Environment(\.seamTheme) private var theme
    @Environment(\.uiEventMonitor) private var uiEventMonitor

    /// The view model driving unlock logic and status presentation.
    @StateObject private var viewModel: SeamUnlockCardViewModel
    /// Style provider used to render error icons, colors, titles, and actions.
    public let errorStyle: SeamAccessCredentialErrorStyle

    /// Creates a new unlock card view.
    /// - Parameters:
    ///   - viewModel: The view model that controls the unlock flow.
    ///   - errorStyle: Optional style for error overlays. Defaults to ``SeamAccessCredentialErrorStyle/default``.
    public init(
        viewModel: SeamUnlockCardViewModel,
        errorStyle: SeamAccessCredentialErrorStyle = .default
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.errorStyle = errorStyle
    }

    public var body: some View {
        VStack {
            VStack {
                HStack {
                    if let currentCredential = viewModel.currentCredential {
                        SeamKeyDetailsView(credential: currentCredential)
                    }
                    Spacer()
                }
                .padding([.horizontal, .top])
                .padding(.vertical, 6)
                Divider()
                    .background(theme.unlockCard.dividerColor)
            }
            .background(theme.unlockCard.headerBackground ?? theme.colors.secondaryBackground)

            Group {
                switch viewModel.state {
                case .idle, .connecting:
                    SeamUnlockCardPhaseView(viewModel: viewModel)
                case .success:
                    SeamUnlockCardStatusView(
                        status: .success,
                        message: "Unlocked!",
                        primaryTitle: "OK",
                        primaryAction: viewModel.reset
                    )
                case .failure(_):
                    SeamUnlockCardStatusView(
                        status: .error,
                        message: "Sorry, something went wrong. Please try again.",
                        primaryTitle: "Try Again",
                        primaryAction: viewModel.reset
                    )
                case .error(let error):
                    SeamUnlockCardErrorView(
                        icon: errorStyle.systemIcon(error, theme),
                        iconColor: errorStyle.iconColor(error, theme),
                        title: errorStyle.title(error),
                        message: errorStyle.message(error),
                        primaryActionTitle: errorStyle.primaryActionTitle(error),
                        primaryAction: viewModel.errorAction(error: error)
                    )
                    .sheet(
                        isPresented: Binding(
                            get: { viewModel.otpWebViewUrl != nil },
                            set: { if !$0 { viewModel.otpWebViewUrl = nil } }
                        )
                    ) {
                        if let url = viewModel.otpWebViewUrl {
                            SeamWebView(url: url)
                                .background(theme.colors.primaryBackground)
                        }
                    }
                }
            }
            .padding(.top)
            .background(theme.unlockCard.cardBackground ?? theme.colors.primaryBackground)
            Spacer()
        }
        // Cancel any in-progress unlock when the card is dismissed.
        .onDisappear(perform: viewModel.cancelUnlock)
        .monitorScreen(appeared: .unlockViewAppeared, disappeared: .unlockViewDisappeared)
    }
}

// MARK: - Internal SeamUnlockCard Subviews

/// Displays the credential's identifying details (name and expiry) along with the provider logo.
struct SeamKeyDetailsView: View {
    @Environment(\.seamTheme) private var theme
    let credential: SeamAccessCredential

    var expiry: String? { credential.expiry?.seamHumanReadableString }
    var roomNumber: String { credential.name }
    var providerImageName: String { credential.providerImageName }


    init(credential: SeamAccessCredential) {
        self.credential = credential
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if !roomNumber.isEmpty {
                    Text(roomNumber)
                        .font(theme.fonts.footnote.weight(.medium))
                        .foregroundStyle(theme.unlockCard.headerTitleColor)
                }
                if let expiry, !expiry.isEmpty {
                    Text("Expires \(expiry)")
                        .font(theme.fonts.footnote)
                        .foregroundStyle(theme.unlockCard.headerSubtitleColor)
                }
            }
            Spacer()
            Image(providerImageName, bundle: .module)
                .renderingMode(.template)
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(theme.unlockCard.providerLogoTint)
        }
    }
}


/// Displays idle, connecting, or unlocking phases, including the animated progress ring and the unlock button.
///
/// Used internally by ``SeamUnlockCardView`` to render the main interaction flow.
struct SeamUnlockCardPhaseView: View {
    @ObservedObject var viewModel: SeamUnlockCardViewModel
    @Environment(\.seamTheme) private var theme

    struct Constants {
        static let imageContentMaxHeight: CGFloat = 156
    }

    var keySizePaddingRatio: CGFloat {
        0.220
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .center) {
                    SeamProgressRing()
                        .opacity(viewModel.isUnlocking ? 1 : 0)
                    keyButton
                }
                .frame(height: min(geometry.size.height * 0.4, Constants.imageContentMaxHeight), alignment: .bottom)
                .padding(.vertical)

                Text(viewModel.phaseTitle)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .font(theme.fonts.title2.weight(.medium))
                    .foregroundStyle(theme.unlockCard.phaseTitleColor)

                Spacer()

                SeamUnlockCardInstructionList(state: viewModel.state)
                    .frame(height: geometry.size.height * 0.4, alignment: .top)
                    .padding(.horizontal)
                    .padding(.horizontal)

                Spacer()
                Spacer()
                if viewModel.isUnlocking {
                    Button("Cancel") {
                        viewModel.cancelUnlock()
                    }
                    .buttonStyle(SeamSecondaryButtonStyle())
                    .padding()
                }
            }
        }
    }

    /// A large circular button with a key icon.
    var keyButton: some View {
        GeometryReader { geometry in
            Button(action: viewModel.startUnlock) {
                Image(systemName: "key")
                    .square()
                    .rotationEffect(Angle(degrees: 90))
                    .foregroundStyle(
                        viewModel.isUnlocking
                        ? theme.unlockCard.keyIconColorActive
                        : theme.unlockCard.keyIconColorIdle
                    )
                    .padding(geometry.size.height * keySizePaddingRatio)
                    .background {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: theme.unlockCard.keyButtonGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: theme.unlockCard.keyButtonShadowColor,
                                radius: theme.unlockCard.keyButtonShadowRadius,
                                x: 0,
                                y: theme.unlockCard.keyButtonShadowYOffset
                            )
                            .opacity(viewModel.isUnlocking ? 0 : 1)
                    }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

/// Step-by-step instructions and animations for the unlock workflow.
///
/// - Parameter state: The current UI ``SeamUnlockCardViewModel/UnlockCardState`` used to drive content.
struct SeamUnlockCardInstructionList: View {
    @Environment(\.seamTheme) private var theme
    let state: SeamUnlockCardViewModel.UnlockCardState

    init(state: SeamUnlockCardViewModel.UnlockCardState) {
        self.state = state
    }

    var body: some View {
        switch state {
        case .connecting:
            VStack {
                Text("Hold the back of your phone against the lock")
                    .font(theme.fonts.callout)
                    .foregroundStyle(theme.unlockCard.instructionTextColor)
                    .padding(.vertical, 4)

                GIFView(.name(gif: "phone-and-salto-lock",
                              loadingImage: "phone-and-salto-lock-first-frame"))
                .frame(minHeight: 0, maxHeight: 200)
                .padding(.top)
            }
        default:
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            bullet("1")
                            Text("Tap button")
                                .font(theme.fonts.footnote)
                        }
                        HStack {
                            bullet("2")
                            Text("Hold phone to lock")
                                .font(theme.fonts.footnote)
                        }
                        HStack {
                            bullet("3")
                            Text("Wait & open door")
                                .font(theme.fonts.footnote)

                        }
                    }
                    .foregroundStyle(theme.unlockCard.instructionTextColor)

                    Spacer()

                    Image("UnlockPictogram", bundle: .module)
                }
            }
        }
    }

    func bullet(_ text: String) -> some View {
        Text(text)
            .font(theme.fonts.footnote.monospacedDigit())
            .foregroundStyle(theme.unlockCard.bulletTextColor)
            .padding(6)
            .background(Circle().fill(theme.unlockCard.bulletBackground))
    }
}

/// Displays unlock success or failure states with icons and actions.
///
/// - Behavior:
///   - On success, auto-dismisses after a short delay by invoking the provided primary action.
///   - On error, displays a retry button with the provided title and action.
struct SeamUnlockCardStatusView: View {
    enum Status {
        case success
        case error
    }

    struct Constants {
        static let imageContentMaxHeight: CGFloat = 156
    }

    @State var autoDismissTask: Task<(), Never>? = nil
    @Environment(\.seamTheme) private var theme

    let status: Status
    let message: String
    let primaryTitle: String
    let primaryAction: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .center) {
                    statusImage
                }
                .frame(height: min(geometry.size.height * 0.4, Constants.imageContentMaxHeight), alignment: .bottom)
                .padding(.vertical)

                Text(message)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .font(theme.fonts.title2.weight(.medium))
                    .foregroundStyle(theme.unlockCard.statusMessageColor)
                Spacer()

                if case .error = status {
                    Button(primaryTitle, action: primaryAction)
                        .buttonStyle(SeamPrimaryButtonStyle())
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            if case .success = status {
                Task {
                    try? await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
                    guard !Task.isCancelled else { return }
                    primaryAction()
                }
            }
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    var statusImage: some View {
        Group {
            switch status {
            case .success:
                if #available(iOS 16.0, *) {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fontWeight(.light)
                        .foregroundColor(theme.unlockCard.successColor)
                } else {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(theme.unlockCard.successColor)                }
            case .error:
                Image(systemName: "key.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.unlockCard.errorColor)
            }
        }
    }
}

/// An overlay for credential errors, rendered with customizable icons, titles, and actions.
///
/// Values are supplied by a ``SeamAccessCredentialErrorStyle`` from ``SeamUnlockCardView``.
struct SeamUnlockCardErrorView: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let primaryActionTitle: LocalizedStringKey?
    let primaryAction: (() -> Void)?
    @Environment(\.seamTheme) private var theme

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(iconColor)

            Text(title)
                .font(theme.fonts.title2)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.center)

            Text(message)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.primaryText)
                .multilineTextAlignment(.center)

            if let primaryActionTitle, let primaryAction {
                Button(primaryActionTitle, action: primaryAction)
                    .buttonStyle(SeamPrimaryButtonStyle())
                    .padding(.top)
            }
            Spacer()
            Spacer()
        }
        .padding()
        .padding(.horizontal)
    }
}


#if DEBUG
#Preview {
    let service = PreviewSeamService(credentials: SeamAccessCredential.credentials)
    let credential = service.credentials.first!
    let viewModel = SeamUnlockCardViewModel(credentialId: credential.id, service: service)

    SeamUnlockMockView()
        .sheet(item: .constant(credential), content: { _ in
            if #available(iOS 16.0, *) {
                SeamUnlockCardView(viewModel: viewModel, errorStyle: .default)
                    .presentationDetents([.medium, .large])
            } else {
                SeamUnlockCardView(viewModel: viewModel, errorStyle: .default)
            }
        })
        .environment(\.seamTheme, SeamTheme.previewTheme)
        .environment(\.uiEventMonitor, UIEventMonitor.disabled)
}

#Preview("Unlock errors") {
    ScrollView {
        let errorCreds = SeamAccessCredential.errorCredentials
        let service = PreviewSeamService(credentials: errorCreds)

        ForEach(errorCreds) { credential in
            let viewModel = SeamUnlockCardViewModel(credentialId: credential.id, service: service)

            SeamUnlockCardView(viewModel: viewModel, errorStyle: .default)
                .environment(\.seamTheme, SeamTheme.previewTheme)
                .environment(\.uiEventMonitor, UIEventMonitor.disabled)
                .padding()

            Divider()
        }
    }
}
#endif
