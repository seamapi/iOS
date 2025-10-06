import SwiftUI

/**
 A lightweight image view for SeamComponents that loads assets from your app bundle or SF Symbols and automatically shows a tasteful placeholder when the view is redacted.

 - Parameters:
   - imageName: The asset name or SF Symbol name to load.
   - location: Where to resolve `imageName` from (app bundle assets or system symbols).
 - Example:
   ```swift
   SeamImageView(imageName: "provider_logo")                 // app asset
   SeamImageView(imageName: "lock.fill", location: .system)  // SF Symbol
   ```
 */
public struct SeamImage: View {
    /// Specifies where to resolve `imageName` from.
    public enum ImageLocation {
        /// Load image from the app's asset catalogs (module first, then main bundle).
        case app
        /// Load SF Symbol via `Image(systemName:)`.
        case system
    }

    /// Current redaction reasons; when non‑empty, a placeholder is shown.
    @Environment(\.redactionReasons) var reasons
    /// The asset or SF Symbol name.
    public let imageName: String
    /// Source for resolving `imageName`. Defaults to `.app` in the initializer.
    public let location: ImageLocation

    private let renderingMode: Image.TemplateRenderingMode?

    private let capInsets: EdgeInsets?
    private let resizingMode: Image.ResizingMode?

    @State private var resolvedAppImage: (name: String, bundle: Bundle)? = nil

    /**
     Creates a `SeamImage`.

     - Parameters:
       - imageName: The asset or SF Symbol name to render.
       - location: The source for `imageName`. Defaults to `.app`.
     */
    public init(_ imageName: String, location: ImageLocation = .app) {
        self.imageName = imageName
        self.location = location
        self.renderingMode = nil
        self.capInsets = nil
        self.resizingMode = nil
    }

    /**
     Creates a `SeamImage`.

     - Parameters:
       - systemName: The SF Symbol name to render.
     */
    public init(systemName: String) {
        self.imageName = systemName
        self.location = .system
        self.renderingMode = nil
        self.capInsets = nil
        self.resizingMode = nil
    }

    fileprivate init(
        imageName: String,
        location: ImageLocation,
        renderingMode: Image.TemplateRenderingMode? = nil,
        capInsets: EdgeInsets? = nil,
        resizingMode: Image.ResizingMode? = nil
    ) {
        self.imageName = imageName
        self.location = location
        self.renderingMode = renderingMode
        self.capInsets = capInsets
        self.resizingMode = resizingMode
    }

    /// Renders either the resolved image or a rounded placeholder when redacted.
    public var body: some View {
        ZStack {
            if reasons.contains(.placeholder) {
                placeholderImage
            } else {
                image
            }
        }
        .onAppear {
            if resolvedAppImage == nil {
                resolvedAppImage = resolveAppImage()
            }
        }
    }

    /**
     Chooses the concrete renderer based on `location`.

     - Returns: App asset renderer when `.app`, else system symbol renderer when `.system`.
     */
    private var image: some View {
        Group {
            if location == .app {
                appImage
            } else if location == .system {
                systemImage
            }
        }
    }

    /**
     Renders a named asset from the app.

     Resolves the image by probing common bundles **once** in priority order and
     then renders only the discovered asset (no double‑drawing):

     1. Package resource bundle (``Bundle/module``)
     2. Main app bundle (``Bundle/main``)
     3. Any other loaded bundles/frameworks

     - Note: Falls back to the main bundle `Image` initializer if no explicit match is found.
     */
    private var appImage: some View {
        Group {
            if let resolvedAppImage {
                if let resizingMode, let capInsets {
                    Image(resolvedAppImage.name, bundle: resolvedAppImage.bundle)
                        .renderingMode(renderingMode)
                        .resizable(capInsets: capInsets, resizingMode: resizingMode)
                        .scaledToFit()
                } else {
                    Image(resolvedAppImage.name, bundle: resolvedAppImage.bundle)
                        .renderingMode(renderingMode)
                        .scaledToFit()
                }
            } else {
                EmptyView()
            }
        }
    }

    /// Renders an SF Symbol using `Image(systemName:)` (resizable, aspect‑fit).
    private var systemImage: some View {
        if let resizingMode, let capInsets {
            Image(systemName: imageName)
                .renderingMode(renderingMode)
                .resizable(capInsets: capInsets, resizingMode: resizingMode)
                .scaledToFit()
        } else {
            Image(systemName: imageName)
                .renderingMode(renderingMode)
                .scaledToFit()
        }
    }

    /**
     A rounded‑corner placeholder used when the view is redacted.

     - Design: Uses the `photo` SF Symbol, is `resizable`, `scaledToFit`, and applies a small corner radius.
     */
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .cornerRadius(6)
    }

    /// Attempts to locate the image in common bundles and returns an `Image` bound to the first match.
    private func resolveAppImage() -> (name: String, bundle: Bundle)? {
        #if canImport(UIKit)
        // Use UIImage(named:in:) so asset catalogs are checked correctly.
        let candidates: [Bundle] = {
            var seen = Set<ObjectIdentifier>()
            var list: [Bundle] = []
            // Priority: module, main, then all others
            let preferred: [Bundle] = [Bundle.module, .main]
            for b in preferred where seen.insert(ObjectIdentifier(b)).inserted { list.append(b) }
            for b in (Bundle.allFrameworks + Bundle.allBundles) where seen.insert(ObjectIdentifier(b)).inserted {
                list.append(b)
            }
            return list
        }()

        for bundle in candidates {
            if UIImage(named: imageName, in: bundle, compatibleWith: nil) != nil {
                return (imageName, bundle)
            }
        }
        return nil
        #else
        // Other platforms: fall back to main bundle lookup via SwiftUI Image
        return (imageName, .module)
        #endif
    }
}

extension SeamImage {
    /**
     Returns a copy configured to use the given template rendering mode,
     mirroring SwiftUI's `Image.renderingMode(_:)` behavior.

     - Parameter renderingMode: The desired template rendering mode (or `nil` to clear it).
     - Returns: A new `SeamImage` applying `renderingMode` to the underlying images.
     */
    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> SeamImage {
        SeamImage(imageName: imageName, location: location, renderingMode: renderingMode,
                  capInsets: capInsets, resizingMode: resizingMode)
    }

    /// Sets the mode by which SwiftUI resizes an image to fit its space.
    /// - Parameters:
    ///   - capInsets: Inset values that indicate a portion of the image that
    ///   SwiftUI doesn't resize.
    ///   - resizingMode: The mode by which SwiftUI resizes the image.
    /// - Returns: An image, with the new resizing behavior set.
    public func resizable(capInsets: EdgeInsets = EdgeInsets(),
                          resizingMode: Image.ResizingMode = .stretch) -> SeamImage {
        SeamImage(imageName: imageName, location: location, renderingMode: renderingMode,
                  capInsets: capInsets, resizingMode: resizingMode)
    }
}

#Preview {
    SeamImage("SeamLogo")
        .resizable()
        .frame(width: 200, height: 200)
    SeamImage(systemName: "key.card")
        .frame(width: 200, height: 200)
}
