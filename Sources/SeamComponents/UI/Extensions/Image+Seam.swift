// MARK: - Seam Image Utilities
import SwiftUI

/// Seam-specific convenience modifiers for `Image`.
extension Image {
    /// Constrains the image within a square container while preserving its aspect ratio.
    ///
    /// Wraps the image in a 1:1 container using a clear `Rectangle` and overlays a
    /// resizable, `.scaledToFit()` version of the image. The container is clipped to
    /// prevent overflow, so non-square images are letterboxed/pillarboxed as needed.
    ///
    /// - Returns: A view that maintains a square aspect ratio and fits the image inside it.
    ///
    /// - Important: Control the rendered size by applying a frame to the result
    ///   (e.g., `.frame(width: 64, height: 64)`).
    ///
    /// - Example:
    /// ```swift
    /// Image("hotel_logo")
    ///     .square()
    ///     .frame(width: 64, height: 64)
    /// ```
    ///
    /// - SeeAlso: ``View/aspectRatio(_:contentMode:)``, ``Image/resizable()``
    @warn_unqualified_access
    func square() -> some View {
        Rectangle()
            .foregroundStyle(Color.clear)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                self
                    .resizable()
                    .scaledToFit()
            )
            .clipShape(Rectangle())
    }
}
