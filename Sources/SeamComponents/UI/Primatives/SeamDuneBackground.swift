import SwiftUI

/// A decorative background that renders soft, layered dunes with gradient lighting.
///
/// ``SeamDuneBackground`` composes three visual layers:
/// 1. A base `LinearGradient` using the provided ``colors``.
/// 2. A subtle center "light" via `RadialGradient` blended with `.screen`.
/// 3. A lower dune silhouette drawn with `Path` and shaded with a vertical gradient.
///
/// - Parameters:
///   - colors: The base gradient palette (top‑leading → bottom‑trailing). Provide at least two colors.
///   - cornerRadius: The corner radius used to clip the composed background (default: `16`).
///
/// - Design Notes:
///   - Uses a continuous rounded rectangle clip for a modern, card‑like appearance.
///   - The dune curve is sized relative to the view via `GeometryReader` for responsive layouts.
///
/// - Example:
/// ```swift
/// SeamDuneBackground(
///     colors: [Color.gray.opacity(0.85), Color.gray.opacity(0.65)],
///     cornerRadius: 16
/// )
/// .frame(width: 300, height: 200)
/// ```
public struct SeamDuneBackground: View {
    /// The base gradient palette rendered from `.topLeading` to `.bottomTrailing`.
    /// Provide at least two colors for a smooth blend.
    public let colors: [Color]

    /// The corner radius applied to the rounded rectangle clip shape.
    public let cornerRadius: CGFloat

    @Environment(\.seamTheme) private var theme

    /// Creates a dune background.
    ///
    /// - Parameters:
    ///   - colors: The gradient colors for the base layer.
    ///   - cornerRadius: The rounded rectangle corner radius. Default is `16`.
    public init(colors: [Color], cornerRadius: CGFloat = 16) {
        self.colors = colors
        self.cornerRadius = cornerRadius
    }

    /// Composes the gradient, highlight, and dune layers and applies the rounded clip.
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base gradient layer.
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                // Bottom leading light highlight blended with .screen for a soft glow.
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.primary.opacity(0.4), location: 0),
                        .init(color: Color.clear, location: 1)
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height)
                )
                .blendMode(.screen)

                // Dune silhouette (lower band) with vertical shading.
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: 0, y: height * 0.7))
                    path.addCurve(
                        to: CGPoint(x: width, y: height * 0.6),
                        control1: CGPoint(x: width * 0.2, y: height * 0.9),
                        control2: CGPoint(x: width * 0.8, y: height * 0.4)
                    )
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: colors.last!.opacity(0.0), location: 0),
                            .init(color: colors.last!.opacity(0.4), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .background(theme.colors.primaryBackground)
            // Clip the composition to a continuous rounded rectangle.
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        }
    }
}

// MARK: - Previews
#if DEBUG
#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        HStack {
            VStack(alignment: .center, spacing: 16) {
                // Neutral gray palette.
                SeamDuneBackground(
                    colors: [Color.gray.opacity(0.85), Color.gray.opacity(0.65)],
                    cornerRadius: 16
                )
                .frame(height: 200)

                // Warm sunset palette.
                SeamDuneBackground(
                    colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                    cornerRadius: 16
                )
                .frame(height: 200)

                // Cool twilight palette.
                SeamDuneBackground(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    cornerRadius: 16
                )
                .frame(height: 200)
            }
            .padding()
        }
    }
    .environment(\.seamTheme, SeamTheme.previewTheme)
}
#endif
