import SwiftUI

/// An indeterminate progress indicator rendered as a rotating gradient arc.
///
/// `SeamProgressRing` provides a lightweight, SwiftUI-first spinner that follows the
/// current ``SeamTheme`` (via the `seamTheme` environment) to color the ring.
///
/// - Design:
///   - Uses a trimmed `Circle` with a fading gradient to suggest motion.
///   - Animates with a continuous 360° rotation.
///   - Thickness and color are derived from the theme and stroke style.
///
/// - Usage:
/// ```swift
/// SeamProgressRing()
///     .frame(width: 32, height: 32)      // size the ring via the view frame
///     .environment(\.seamTheme, .default) // optional: provide a theme
/// ```
///
/// - Important: The ring starts animating on appearance and runs indefinitely until
///   the view disappears.
public struct SeamProgressRing: View {
    /// The current theme, injected from the environment, used to derive ring colors.
    @Environment(\.seamTheme) private var theme
    /// Internal flag that drives the rotation animation.
    @State private var isAnimating = false

    struct Constants {
        static let strokeWidth = 10.0
    }

    /// Creates a progress ring view.
    public init() { }

    public var body: some View {
        ZStack {
            // Rotating gradient arc representing indeterminate progress.
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: theme.colors.progress.opacity(1), location: 0),
                            .init(color: theme.colors.progress.opacity(0), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: Constants.strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .padding(Constants.strokeWidth / 2)
        }
        // Start the infinite rotation animation when the view appears.
        .onAppear {
            isAnimating = true
        }
    }
}


#if DEBUG
#Preview {
    SeamProgressRing()
        .frame(width: 120, height: 120)
        .environment(\.seamTheme, SeamTheme.previewTheme)
}
#endif
