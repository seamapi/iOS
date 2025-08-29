import SwiftUI
/// An effect that overlays a sweeping highlight over the provided content.
///
/// The shimmer is implemented using a `LinearGradient` that animates from `startPoint` to `endPoint`
/// and is **masked** by the original content, preserving the view’s shape and fill. The animation is
/// automatically disabled when **Reduce Motion** is turned on.
///
/// - Important: The effect uses an oversized, rotated gradient and off-screen rendering hints
///   to avoid clipping and to maintain smooth animation on large card views.
///
/// - SeeAlso: `View/shimmer(active:redact:)`
public struct ShimmerEffect: ViewModifier {
    /// Internal trigger used to kick off the first animation frame.
    ///
    /// Starts as `true` so the gradient begins off-screen and animates into place
    /// on appear when toggled to `false`.
    @State private var viewDidAppear = true

    /// Respect the user's **Reduce Motion** accessibility setting.
    /// When enabled, the shimmer animation is disabled.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Current color scheme used to select a light or dark highlight color.
    @Environment(\.colorScheme) private var colorScheme

    /// When `true`, applies `.redacted(reason: .placeholder)` to the content while shimmering.
    private let redact: Bool

    /// Animation and geometry constants for the shimmer effect.
    struct Constants {
        /// A linear, repeating animation for the sweeping highlight.
        static let animation = Animation.linear(duration: 1.75).delay(0.25).repeatForever(autoreverses: false)

        /// Off-screen start coordinate for the gradient (normalized unit space).
        static let min = -0.3

        /// Off-screen end coordinate for the gradient (normalized unit space).
        static let max = 1.3
    }

    /// The animated highlight gradient.
    ///
    /// Uses a high-contrast center stop and two softer edges, switching
    /// to white in dark mode and black in light mode.
    var gradient: Gradient {
        let color = colorScheme == .dark ? Color.white : Color.black
        return Gradient(colors: [color.opacity(0.3), color, color.opacity(0.3)])
    }

    /// The starting point of the sweep in unit space.
    ///
    /// Begins off-screen then animates toward the content on appear.
    var startPoint: UnitPoint {
        viewDidAppear ? UnitPoint(x: Constants.min, y: Constants.min) : UnitPoint(x: 1, y: 1)
    }

    /// The ending point of the sweep in unit space.
    ///
    /// Animates beyond the far edge to avoid clipping on large surfaces.
    var endPoint: UnitPoint {
        viewDidAppear ? UnitPoint(x: 0, y: 0) : UnitPoint(x: Constants.max, y: Constants.max)
    }

    /// Creates a shimmer effect with the default animation timing and gradient stops.
    ///
    /// Use the `redact` parameter to automatically apply `.redacted(reason: .placeholder)` to the
    /// content while shimmering. This is **enabled by default** to produce a conventional skeleton look.
    ///
    /// - Parameter redact: Whether to apply redaction to the content while shimmering. Defaults to `true`.
    public init(redact: Bool = true) {
        self.redact = redact
    }

    /// Applies the animated gradient mask to `content` and manages lifecycle.
    ///
    /// Disables animation when **Reduce Motion** is enabled. On appear, toggles
    /// the internal flag to start the sweep.
    public func body(content: Content) -> some View {
        applyingGradient(to: content)
            .animation(reduceMotion ? nil : Constants.animation, value: viewDidAppear)
            .onAppear {
                DispatchQueue.main.async {
                    viewDidAppear = false
                }
            }
    }

    /// Applies the shimmer gradient to `content` using masking.
    ///
    /// This method is exposed for advanced composition (e.g., when you need to insert additional layers
    /// between the content and the mask). For typical use, prefer the `View.shimmer(active:)` convenience.
    ///
    /// - Parameter content: The view to which the animated highlight will be applied.
    /// - Returns: A view that renders `content` with a shimmer overlay.
    @ViewBuilder public func applyingGradient<V: View>(to content: V) -> some View {
        if redact {
            content
                .redacted(reason: .placeholder)
                .mask(
                    LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)
                        .compositingGroup()
                        .drawingGroup()
                )
        } else {
            content.mask(
                LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)
                    .compositingGroup()
                    .drawingGroup()
            )
        }
    }
}

public extension View {
    /// Adds a shimmer loading effect to any view.
    ///
    /// The shimmer animates when `active` is `true`. If `active` is `false`, the original view is returned
    /// unchanged. The effect respects **Reduce Motion**, presenting a static highlight when enabled.
    ///
    /// - Parameters:
    ///   - active: Whether the shimmer should animate. Defaults to `true`.
    ///   - redact: Whether to apply `.redacted(reason: .placeholder)` to the content while shimmering. Defaults to `true`.
    /// - Returns: A view that conditionally applies the shimmer effect.
    ///
    /// ### Example
    /// ```swift
    /// VStack {
    ///   ProfileHeaderSkeleton()
    ///     .shimmer(active: isLoading, redact: true)
    ///
    ///   ForEach(0..<3, id: \.self) { _ in
    ///     PostSkeletonCard().shimmer(active: isLoading, redact: false) // keep original fills
    ///   }
    /// }
    /// ```
    @ViewBuilder func shimmer(active: Bool = true, redact: Bool = true) -> some View {
        if active {
            modifier(ShimmerEffect(redact: redact))
        } else {
            self
        }
    }
}

#if DEBUG
#Preview {
    Text("Hello, World!")
        .shimmer()
}
#endif
