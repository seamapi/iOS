import SwiftUI
import UIKit
import Combine

// MARK: - Model
/// Style variants for in‑app toast notifications.
///
/// Each style maps to an SF Symbol via ``systemImage`` and is typically paired with
/// a themed color in ``SeamToastView``.
///
/// - SeeAlso: ``SeamToastItem``, ``SeamToastCenter``, ``SeamToastView``
public enum SeamToastStyle {
    case info
    case success
    case warning
    case error
    
    /// An SF Symbol name appropriate for the style.
    ///
    /// - Returns: A filled symbol for visual clarity on light and dark backgrounds.
    public var systemImage: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        }
    }
}

/// A value describing a single toast presentation.
///
/// Includes content (``title``, ``message``), a visual ``style``, and behavior flags such
/// as ``haptics`` and ``allowsTapToDismiss``. If no explicit duration is provided, a sensible
/// default is computed based on message length to improve readability.
///
/// - Example:
/// ```swift
/// let item = SeamToastItem(
///   title: "Instant Keys",
///   message: "Link opened",
///   style: .success
/// )
/// ```
public struct SeamToastItem: Identifiable, Equatable {
    /// Stable identifier used by SwiftUI.
    public let id = UUID()
    /// Short, prominent title text.
    public let title: String
    /// Supporting message text (1–3 sentences recommended).
    public let message: String
    /// Visual emphasis and icon mapping for the toast.
    public let style: SeamToastStyle
    /// Display duration in seconds.
    ///
    /// If not specified in the initializer, a default is derived from the combined
    /// title + message length with a minimum of 2.5s.
    public let duration: TimeInterval
    /// Whether to play a haptic feedback when the toast appears.
    public let haptics: Bool
    /// When `true`, shows a close affordance and allows tapping the toast to dismiss.
    public let allowsTapToDismiss: Bool

    /// Creates a toast item.
    ///
    /// - Parameters:
    ///   - title: Short title text.
    ///   - message: Supporting message text.
    ///   - style: Visual style. Default: `.info`.
    ///   - duration: Optional explicit duration in seconds. If `nil`, a default is computed
    ///               from the approximate word count (min 2.5s).
    ///   - haptics: Play haptic feedback on show. Default: `true`.
    ///   - allowsTapToDismiss: Enable tap‑to‑dismiss behavior. Default: `false`.
    public init(title: String,
                message: String,
                style: SeamToastStyle = .info,
                duration: TimeInterval? = nil,
                haptics: Bool = true,
                allowsTapToDismiss: Bool = false
    ) {
        let averageReadingRate: Double = (60 / 225)
        let minumumDisplayDuration: Double = 2.5
        let wordCount = Double((title + message).count { $0 == " " } + 2)
        let messageLengthBasedDuration = max(minumumDisplayDuration, (wordCount * averageReadingRate))

        self.title = title
        self.message = message
        self.style = style
        self.duration = duration ?? messageLengthBasedDuration
        self.haptics = haptics
        self.allowsTapToDismiss = allowsTapToDismiss
    }
}

// MARK: - Center (singleton)

/// A main‑actor singleton that queues and displays toasts at the top of the screen.
///
/// Use ``show(title:message:style:duration:haptics:allowsTapToDismiss:)`` to enqueue a toast.
/// The center ensures only one toast is visible at a time and automatically advances through
/// a FIFO queue with fade transitions. Use ``hide(reason:)`` to dismiss the current toast early.
///
/// - Important: UI state (``current``) and scheduling are managed on the main actor.
@MainActor
public class SeamToastCenter: ObservableObject {
    /// Shared global instance.
    public static let shared = SeamToastCenter()

    /// The currently presented toast, if any.
    @Published public private(set) var current: SeamToastItem?
    /// Auto‑dismiss task scheduled for the visible toast.
    private var dismissTask: Task<Void, Never>?
    /// FIFO queue of pending toasts.
    private var queue: [SeamToastItem] = []
    /// Theme used by the overlay window to style the toast view.
    @Published public var theme: SeamTheme = .default
    /// Fade‑out animation duration used when hiding a toast.
    private let dismissAnimationDuration: TimeInterval = 0.25

    private init() {}

    /// Enqueue and present a toast globally.
    ///
    /// Call from anywhere on the main actor. If a toast is already visible, the new item is
    /// queued and displayed when the current one finishes.
    ///
    /// - Parameters:
    ///   - title: Title text.
    ///   - message: Body text.
    ///   - style: Visual style.
    ///   - duration: Optional explicit display duration.
    ///   - haptics: Whether to vibrate on show.
    ///   - allowsTapToDismiss: Enables tap‑to‑dismiss and shows a close button.
    public func show(title: String,
                     message: String,
                     style: SeamToastStyle = .info,
                     duration: TimeInterval? = nil,
                     haptics: Bool = true,
                     allowsTapToDismiss: Bool = false) {
        let toast = SeamToastItem(title: title, message: message, style: style, duration: duration, haptics: haptics, allowsTapToDismiss: allowsTapToDismiss)
        // Enqueue and present if idle.
        queue.append(toast)
        presentNextIfNeeded()
    }

    /// Presents the next queued toast if none is currently visible.
    ///
    /// Configures the overlay window, plays haptics, and starts the auto‑dismiss timer.
    private func presentNextIfNeeded() {
        // If something is already visible, we wait until it's dismissed.
        guard current == nil, !queue.isEmpty else { return }
        // Ensure overlay window is visible and themed.
        SeamToastOverlayWindow.shared.show(theme: theme)
        let next = queue.removeFirst()
        current = next

        if next.haptics {
            switch next.style {
            case .success:
                SeamHaptics.success()
            case .error:
                SeamHaptics.error()
            case .warning:
                SeamHaptics.warning()
            case .info:
                SeamHaptics.info()
            }
        }

        // Start auto-dismiss for this specific toast.
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            let nanos = UInt64((next.duration * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: nanos)
            self?.hide(reason: "timeout")
        }
    }

    /// Dismisses the current toast, optionally specifying a reason.
    ///
    /// After the fade completes, the next queued toast (if any) is presented; otherwise, the
    /// overlay window is hidden.
    ///
    /// - Parameter reason: An optional reason useful for debugging (e.g., "timeout", "tap").
    public func hide(reason: String = "manual") {
        dismissTask?.cancel()
        dismissTask = nil
        let fade = dismissAnimationDuration
        withAnimation(.easeOut(duration: fade)) {
            current = nil
        }
        // After the fade completes, either show the next toast or hide the overlay window.
        Task { [weak self] in
            let nanos = UInt64((fade * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: nanos)
            await MainActor.run {
                if let self, !self.queue.isEmpty {
                    self.presentNextIfNeeded()
                } else {
                    SeamToastOverlayWindow.shared.hide()
                }
            }
        }
    }
}

// MARK: - Overlay UIWindow (Top-of-screen rendering)

/// Manages a transparent overlay `UIWindow` pinned to the top of the active scene.
///
/// Hosts a SwiftUI hierarchy containing the toast view and ensures touch‑through to
/// underlying content.
@MainActor
final class SeamToastOverlayWindow {
    static let shared = SeamToastOverlayWindow()

    private var window: UIWindow?
    private var host: UIHostingController<Root>?

    /// Shows (or reconfigures) the overlay window and applies the provided theme.
    func show(theme: SeamTheme) {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
        guard let scene = windowScenes.first(where: { $0.activationState == .foregroundActive })
                ?? windowScenes.first(where: { $0.activationState == .foregroundInactive }) else {
            print("No window scene found")
            return
        }

        if window == nil || window?.windowScene !== scene {
            let w = UIWindow(windowScene: scene)
            w.backgroundColor = .clear
            w.windowLevel = .alert + 1   // above sheets/fullScreenCovers
            let root = Root(seamTheme: theme)
            let hc = UIHostingController(rootView: root)
            hc.view.backgroundColor = .clear
            w.rootViewController = hc
            window = w
            host = hc
        } else {
            host?.rootView = Root(seamTheme: theme)
        }
        window?.isHidden = false
    }

    /// Hides the overlay window without destroying it.
    func hide() {
        window?.isHidden = true
    }

    /// Root SwiftUI container rendered inside the overlay window.
    private struct Root: View {
        @StateObject private var center = SeamToastCenter.shared
        let theme: SeamTheme

        init(seamTheme: SeamTheme) {
            self.theme = seamTheme
        }

        var body: some View {
            ZStack(alignment: .top) {
                // Fullscreen, touch-through layer (keeps underlying UI interactive)
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)

                if let toast = center.current {
                    SeamToastView(toast: toast) {
                        center.hide(reason: "tap")
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .environment(\.seamTheme, theme)
            .animation(.easeInOut(duration: 0.25), value: center.current)
        }
    }
}

// MARK: - Toast View

/// A SwiftUI view that renders a single toast item.
///
/// Resolves the leading icon from ``SeamToastStyle`` and applies theme colors. When
/// ``SeamToastItem/allowsTapToDismiss`` is `true`, a close button is shown and tapping the
/// banner will dismiss it via the provided closure.
///
/// - SeeAlso: ``SeamToastCenter``
public struct SeamToastView: View {
    @Environment(\.seamTheme) private var theme
    /// The model describing what to display.
    public let toast: SeamToastItem
    /// Action invoked when the user requests dismissal.
    public let onDismiss: () -> Void

    /// Creates a toast view.
    /// - Parameters:
    ///   - toast: The item to render.
    ///   - onDismiss: Closure to call when the toast should be dismissed.
    public init(toast: SeamToastItem, onDismiss: @escaping () -> Void) {
        self.toast = toast
        self.onDismiss = onDismiss
    }

    public var body: some View {
        // Resolve the accent color from the theme based on the toast style.
        let accent: Color = {
            switch toast.style {
            case .info:    return theme.colors.info
            case .success: return theme.colors.success
            case .warning: return theme.colors.warning
            case .error:   return theme.colors.error
            }
        }()

        HStack {
            Image(systemName: toast.style.systemImage)
                .imageScale(.large)
                .foregroundStyle(accent)

            VStack(alignment: .leading) {
                Text(toast.title)
                    .font(theme.fonts.callout.weight(.medium))
                    .foregroundStyle(theme.toast.textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(toast.message)
                    .font(theme.fonts.callout)
                    .foregroundStyle(theme.toast.textColor)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
            }

            if toast.allowsTapToDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(theme.fonts.caption)
                        .padding(6)
                        .background(theme.colors.grayFill, in: Circle())
                        .accessibilityLabel("Dismiss")
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.toast.horizontalPadding)
        .padding(.vertical, theme.toast.verticalPadding)
        .background {
            RoundedRectangle(cornerRadius: theme.toast.cornerRadius, style: .continuous)
                .fill(theme.toast.background)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.toast.cornerRadius, style: .continuous)
                        .strokeBorder(theme.toast.borderColor, lineWidth: 1)
                )
                .shadow(color: theme.toast.shadowColor, radius: theme.toast.shadowRadius, y: theme.toast.shadowYOffset)
        }
        .tint(accent)
        // Combine title and message into a single accessible element.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .onTapGesture {
            guard toast.allowsTapToDismiss else { return }
            onDismiss()
        }
    }
}

// MARK: - Theme Bridge

/// Keeps the overlay window in sync with the current ``SeamTheme``.
///
/// Embed this once near the top of your scene/view hierarchy to propagate theme updates
/// to the toast overlay.
///
/// - Example:
/// ```swift
/// WindowGroup {
///   RootView()
///     .background(SeamToastThemeBridge())
/// }
/// ```
public struct SeamToastThemeBridge: View {
    @Environment(\.seamTheme) private var theme
    @StateObject private var center = SeamToastCenter.shared

    /// Creates a theme bridge.
    public init() {}
    /// A transparent view that updates the center's theme on appear/change.
    public var body: some View {
        Color.clear
            .onAppear { center.theme = theme }
            .onChange(of: theme) { center.theme = $0 }
    }
}

#if DEBUG

private struct ToastPreviewScreen: View {
    @State private var duration: Double = 2.5
    @State private var allowsTapToDismiss: Bool = false
    @State private var autoDemoRunning: Bool = false
    @State private var showSheet: Bool = false
    @Environment(\.seamTheme) private var theme

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack {
                    toastSelectionView
                }
                .sheet(isPresented: $showSheet) {
                    toastSelectionView
                }
            }
            .background(SeamToastThemeBridge())
        } else {
            NavigationView {
                VStack { toastSelectionView }
                .sheet(isPresented: $showSheet) { toastSelectionView }
            }.background(SeamToastThemeBridge())
        }
    }

    private var toastSelectionView: some View {
        List {
            Section("Show one".excludeLocalization) {
                HStack {
                    Button("Info".excludeLocalization)     { show(.info) }
                    Button("Success".excludeLocalization)  { show(.success) }
                    Button("Warning".excludeLocalization)  { show(.warning) }
                    Button("Error".excludeLocalization)    { show(.error) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Section("Queue".excludeLocalization) {
                Button("Queue 3 mixed".excludeLocalization) { queueMixed() }
                Button("Queue 5 (random)".excludeLocalization) { queueRandom(count: 5) }
                    .buttonStyle(.bordered)
            }

            Section("Options".excludeLocalization) {
                HStack {
                    Text("Duration".excludeLocalization)
                    Slider(value: $duration, in: 1.0...5.0, step: 0.5) {
                        Text("Duration".excludeLocalization)
                    } minimumValueLabel: {
                        Text("1s".excludeLocalization).font(theme.fonts.caption)
                    } maximumValueLabel: {
                        Text("5s".excludeLocalization).font(theme.fonts.caption)
                    }
                    Text(String(format: "%.1fs".excludeLocalization, duration))
                        .font(theme.fonts.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }
                Toggle("Allow tap to dismiss".excludeLocalization, isOn: $allowsTapToDismiss)
            }

            Section {
                Button(showSheet ? "Hide Sheet".excludeLocalization : "Show Sheet".excludeLocalization) {
                    showSheet.toggle()
                }
            }

            if autoDemoRunning {
                Section {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Running auto demo…".excludeLocalization)
                            .font(theme.fonts.footnote)
                    }
                }
            }
        }
        .navigationTitle("Toast Preview".excludeLocalization)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(autoDemoRunning ? "Demo…".excludeLocalization : "Run Demo".excludeLocalization) { runDemo() }
                    .disabled(autoDemoRunning)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear".excludeLocalization) { SeamToastCenter.shared.hide() }
            }
        }
    }

    // MARK: - Actions

    private func show(_ style: SeamToastStyle, _ message: String? = nil) {
        let title = "Instant Keys"
        let msg: String
        switch style {
        case .info:    msg = message ?? "Loading your instant keys…"
        case .success: msg = message ?? "Instant keys link opened"
        case .warning: msg = message ?? "The Instant Keys link has expired. Keeping your existing keys."
        case .error:   msg = message ?? "Something went wrong"
        }
        SeamToastCenter.shared.show(title: title,
                                    message: msg,
                                    style: style,
                                    duration: duration,
                                    haptics: false, // keep previews quiet
                                    allowsTapToDismiss: allowsTapToDismiss)
    }
    
    private func queueMixed() {
        show(.info, "Loading your instant keys…")
        show(.success, "Instant keys link opened")
        show(.warning, "The Instant Keys link has expired. Keeping your existing keys.")
    }

    private func queueRandom(count: Int) {
        let styles: [SeamToastStyle] = [.info, .success, .warning, .error]
        for i in 1...count {
            let k = styles.randomElement() ?? .info
            show(k, "Queued #\(i) – \(label(for: k))")
        }
    }

    private func runDemo() {
        guard !autoDemoRunning else { return }
        autoDemoRunning = true
        Task {
            defer { autoDemoRunning = false }
            show(.info, "Handling deep link…".excludeLocalization)
            try? await Task.sleep(nanoseconds: nanos(duration + 0.1))
            show(.success, "Deep link opened".excludeLocalization)
            try? await Task.sleep(nanoseconds: nanos(duration + 0.1))
            show(.warning, "Verifying credentials".excludeLocalization)
            try? await Task.sleep(nanoseconds: nanos(duration + 0.1))
            show(.error, "Unlock failed – try again".excludeLocalization)
        }
    }

    private func label(for style: SeamToastStyle) -> String {
        switch style {
        case .info: return "Info"
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    private func nanos(_ seconds: Double) -> UInt64 {
        UInt64((seconds * 1_000_000_000).rounded())
    }
}

// MARK: - Previews

#Preview("Default Theme") {
    ToastPreviewScreen()
}

#Preview("Custom Toast Theme") {
    let custom = SeamTheme.default.with(
        toast: .default.with(
            background: .black.opacity(0.88),
            textColor: .white,
            borderColor: .white.opacity(0.18),
            cornerRadius: 18,
            shadowColor: .black.opacity(0.35),
            shadowRadius: 14,
            shadowYOffset: 8
        )
    )
    return ToastPreviewScreen()
        .environment(\.seamTheme, custom)
}

#endif
