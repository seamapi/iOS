import Foundation

/**
 Central registry for Seam service implementations.

 Use this to inject a real ("live") implementation at runtime while keeping a
 compile‑time‑safe fallback to a preview/mock service for development, tests,
 and Xcode Previews. The ``AutoSeamService`` proxy exposes a single, stable
 handle you can pass through your UI; it automatically mirrors whichever
 service is currently registered.

 Changing ``live`` or ``mock`` automatically re‑attaches
 ``AutoSeamService`` so your UI observes the new source of truth.

 - Important: **Automatic registration:** When you link ``SeamMobileKit``, the **SeamSDK** is automatically registered as the ``live`` service during SDK initialization. Most apps do not need to set ``live`` manually; you can override it for testing or with a custom implementation.

 - Note: All APIs in this file are `@MainActor`. Interact with them on the
 main thread, as they drive UI state and SwiftUI publishers.
 - SeeAlso: ``SeamServiceProtocol``, ``AutoSeamService``
 */
@MainActor
public enum SeamServiceRegistry {
    /// Semantic version of the registry contract. Bump when registry semantics change.
    public static var version = "1.0.0"

    /// Production service instance used by the app.
    /// Automatically set by ``SeamMobileKit`` when SeamSDK is present; override after authentication if needed.
    public static var live: (any SeamServiceProtocol)? = nil {
        didSet { AutoSeamService.shared.refreshRegistry() }
    }

    /// Default fallback used when ``live`` is `nil`. Suitable for previews/tests.
    public private(set) static var mock: any SeamServiceProtocol = PreviewSeamService.shared {
        didSet { AutoSeamService.shared.refreshRegistry() }
    }

    /// Stable proxy that targets ``live`` when set, otherwise ``mock``.
    public static let auto: any SeamServiceProtocol = AutoSeamService.shared
}
