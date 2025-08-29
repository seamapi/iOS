import SwiftUI
import SafariServices

/// A SwiftUI wrapper for presenting an in‑app Safari view.
///
/// `SeamWebView` hosts an `SFSafariViewController` to show web content (e.g., OTP
/// authorization or support pages) without leaving your app. When the user taps **Done**
/// or otherwise dismisses the sheet, the optional `onClose` callback is invoked.
///
/// - Important: `SFSafariViewController` shares cookies and website data with Safari
///   and supports Reader, AutoFill, and Keychain where applicable.
///
/// - Example:
/// ```swift
/// struct OTPView: View {
///     @State private var showWeb = false
///     var body: some View {
///         Button("Open OTP") { showWeb = true }
///         .sheet(isPresented: $showWeb) {
///             SeamWebView(url: URL(string: "https://example.com/otp")!) {
///                 // Refresh state after the user closes the web view
///             }
///         }
///     }
/// }
/// ```
public struct SeamWebView: UIViewControllerRepresentable {
    /// The URL to load in the in‑app Safari view.
    let url: URL
    /// Optional callback invoked when the user dismisses the Safari view.
    let onClose: (() -> Void)?

    // MARK: - Initializer
    /// Creates a new web view wrapper.
    ///
    /// - Parameters:
    ///   - url: The web page to display.
    ///   - onClose: An optional closure called when the user taps **Done**.
    public init(url: URL, onClose: (() -> Void)? = nil) {
        self.url = url
        self.onClose = onClose
    }

    // MARK: - UIViewControllerRepresentable
    /// Creates and configures the underlying `SFSafariViewController`.
    ///
    /// Sets the coordinator as the delegate to observe user dismissal.
    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    /// Updates the existing Safari controller.
    ///
    /// No dynamic updates are required after initial creation.
    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }

    /// Creates the delegate coordinator that bridges Safari events back to SwiftUI.
    public func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose)
    }

    /// Delegate object for `SFSafariViewController` that relays dismissal events.
    public class Coordinator: NSObject, SFSafariViewControllerDelegate {
        /// Closure to invoke when the Safari view is dismissed.
        let onClose: (() -> Void)?

        /// Creates a coordinator.
        /// - Parameter onClose: The dismissal callback to relay to SwiftUI.
        init(onClose: (() -> Void)? = nil) {
            self.onClose = onClose
        }

        /// Called when the user taps **Done** or otherwise dismisses the Safari view.
        public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onClose?()
        }
    }
}
