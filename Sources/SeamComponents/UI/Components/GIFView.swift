import SwiftUI
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

/// A lightweight SwiftUI view that renders animated GIFs from a name, raw data, or URL.
///
/// ``GIFView`` wraps a `UIImageView` under the hood to play animated images decoded by a
/// minimal GIF decoder. It supports three sources via ``GIFView/Source`` and exposes a
/// familiar `UIView.ContentMode` for sizing behavior.
///
/// - Important: Loading and state updates are performed on the main actor. Remote loading
///   honors `URLCache` through `URLSession.shared.data(from:)`.
///
/// - Topics:
///   - Usage
///   - Sources
///   - Sizing & scale
///
/// ### Usage
/// ```swift
/// // From asset in bundle ("example.gif")
/// GIFView(.name(gif: "example"))
///
/// // From remote URL
/// GIFView(.url(URL(string: "https://…/image.gif")!))
///
/// // From raw Data
/// GIFView(.data(gifData))
/// ```
///
/// ### Sources
/// Use ``GIFView/Source`` to specify where the GIF comes from.
///
/// ### Sizing & scale
/// Provide a `contentMode` to control layout within the SwiftUI container. See
/// ``GIFView/init(_:contentMode:)``.
public struct GIFView: View {
    /// A source for an animated GIF.
    ///
    /// - Cases:
    ///   - ``name(gif:loadingImage:inBundle:)``: Load from a GIF file in a bundle.
    ///   - ``data(_:)``: Render from raw GIF data already in memory.
    ///   - ``url(_:)``: Fetch from a remote URL (uses `URLSession.shared`).
    public enum Source: Equatable {
        /// Load a GIF by file name.
        /// - Parameters:
        ///   - gif: The resource name (with or without the `.gif` extension).
        ///   - loadingImage: Optional placeholder image name displayed while loading.
        ///   - inBundle: The bundle to search; defaults to the module bundle when `nil`.
        case name(gif: String, loadingImage: String? = nil, inBundle: Bundle? = nil)
        /// Render from raw GIF data already in memory.
        case data(Data)
        /// Fetch and render a GIF from a remote URL. Honors `URLCache`.
        case url(URL)
    }

    /// The configured image source to load.
    private let source: Source
    /// The sizing behavior applied to the underlying `UIImageView`.
    private let contentMode: UIView.ContentMode

    /// The loaded GIF bytes for the active source, if available.
    @State private var data: Data?
    /// The base screen scale used when constructing `UIImage` frames.
    private let screenScale: CGFloat = UIScreen.main.scale

    /// Creates a GIF view.
    ///
    /// - Parameters:
    ///   - source: Where to load the GIF from.
    ///   - contentMode: The `UIImageView` content mode used for sizing within the available space.
    public init(_ source: Source, contentMode: UIView.ContentMode = .scaleAspectFit) {
        self.source = source
        self.contentMode = contentMode
    }

    public var body: some View {
        Group {
            if let data {
                // Apply a calibrated scale multiplier to align visual size across devices.
                // Some animated GIFs are authored at 1×; bumping the effective scale helps
                // avoid soft rendering on high-DPI screens.
                GIFImageView(data: data, contentMode: contentMode, screenScale: screenScale * 1.25)
            } else if case let .name(_, loadingImage, bundle) = source, let loadingImage {
                Image(loadingImage, bundle: bundle)
            } else {
                ProgressView()
            }
        }
        // Load (or re-load) when the source changes.
        .task(id: source) { await load() }
    }

    /// Loads GIF data for the configured source.
    ///
    /// - Behavior:
    ///   - ``Source/name(gif:loadingImage:inBundle:)``: Reads from the provided bundle, defaulting to `.module`.
    ///   - ``Source/data(_:)``: Assigns the provided data.
    ///   - ``Source/url(_:)``: Fetches using `URLSession.shared.data(from:)`; errors yield `nil` data.
    @MainActor
    private func load() async {
        switch source {
        case let .name(gif, _, bundle):
            let bundle = bundle ?? .module
            if let url = bundle.url(forResource: gif.replacingOccurrences(of: ".gif", with: ""), withExtension: "gif"),
               let d = try? Data(contentsOf: url) {
                self.data = d
            } else {
                self.data = nil
            }

        case let .data(d):
            self.data = d

        case let .url(url):
            do {
                // Honor URLCache; use a simple fetch
                let (d, _) = try await URLSession.shared.data(from: url)
                self.data = d
            } catch {
                self.data = nil
            }
        }
    }
}

/// A `UIViewRepresentable` that hosts a `UIImageView` to animate decoded GIF frames.
///
/// Configures an animated `UIImage` from decoded frames and total duration. When decoding
/// fails, clears the image and stops animation to conserve resources.
private struct GIFImageView: UIViewRepresentable {
    let data: Data
    let contentMode: UIView.ContentMode
    let screenScale: CGFloat

    /// Creates the `UIImageView` and applies initial configuration.
    func makeUIView(context: Context) -> UIImageView {
        let v = UIImageView()
        v.contentMode = contentMode
        v.clipsToBounds = true
        v.backgroundColor = .clear
        configure(v)
        return v
    }

    /// Reconfigures the existing `UIImageView` when SwiftUI updates the view.
    func updateUIView(_ uiView: UIImageView, context: Context) {
        configure(uiView)
    }

    /// Decodes frames and updates the `UIImageView` with an animated image.
    private func configure(_ iv: UIImageView) {
        guard let decoded = GIFDecoder.decodeGIF(data, screenScale: screenScale) else {
            iv.image = nil
            iv.stopAnimating()
            iv.animationImages = nil
            return
        }
        // Build an animated UIImage from frames + total duration.
        iv.image = UIImage.animatedImage(with: decoded.frames, duration: decoded.duration)
        iv.startAnimating()
    }
}

/// Minimal GIF decoder that extracts frames and per-frame delays using ImageIO.
private enum GIFDecoder {
    /// The decoded frames and total animation duration.
    struct Result {
        /// The ordered frames that compose the animated image.
        let frames: [UIImage]
        /// The total animation duration in seconds for all frames.
        let duration: TimeInterval
    }

    /// Decodes a GIF from raw data.
    /// - Parameters:
    ///   - data: Raw GIF bytes.
    ///   - screenScale: The scale to apply to each `UIImage` frame.
    /// - Returns: A ``Result`` containing frames and total duration, or `nil` on failure.
    static func decodeGIF(_ data: Data, screenScale: CGFloat) -> Result? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetType(src) != nil else { return nil }

        let count = CGImageSourceGetCount(src)
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0

        images.reserveCapacity(count)

        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(src, i, nil) else { continue }
            let frameDuration = frameDelay(for: src, index: i)
            totalDuration += frameDuration
            images.append(UIImage(cgImage: cg, scale: screenScale, orientation: .up))
        }

        // Fallback duration if metadata missing
        if totalDuration == 0 { totalDuration = Double(count) * 0.1 }

        return images.isEmpty ? nil : Result(frames: images, duration: totalDuration)
    }

    /// Extracts the per-frame delay, clamping very small values to avoid excessively fast frames.
    ///
    /// Uses the GIF unclamped delay time when present, falling back to the clamped delay time.
    private static func frameDelay(for src: CGImageSource, index: Int) -> TimeInterval {
        guard let props = CGImageSourceCopyPropertiesAtIndex(src, index, nil) as? [CFString: Any],
              let gifDict = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }

        // Prefer unclamped; fallback to clamped.
        let unclamped = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber
        let clamped   = gifDict[kCGImagePropertyGIFDelayTime] as? NSNumber
        let raw = unclamped?.doubleValue ?? clamped?.doubleValue ?? 0.1

        // Safari/WebKit clamp behavior guidance; avoid zero/too-fast frames.
        let minFrame = 0.02
        return max(raw, minFrame)
    }
}

// MARK: - Previews & Usage Examples

struct GIFView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // From bundle
            GIFView(.name(gif: "example")) // example.gif in the main bundle

            // From remote URL
            GIFView(.url(URL(string: "https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif")!))

            // With different sizing behavior
            GIFView(.name(gif: "example"), contentMode: .scaleAspectFill)
                .frame(height: 120)
                .clipped()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
