import Foundation
#if canImport(UIKit)
import UIKit
#endif

/**
# SeamHaptics

 Lightweight helpers to trigger system haptic feedback.

 Each static method triggers a standard haptic pattern and manages
 generator lifecycle for you (no manual generator retention required).
 Calls are dispatched to `@MainActor` tasks.

 - Important: These APIs are guarded by `#if canImport(UIKit)`. On platforms
   without UIKit or haptic hardware, calls are no‑ops.

 - Example:
   ```swift
   Button("Unlock") {
     SeamHaptics.prepare() // optional pre-warm for lower latency
     SeamHaptics.success()
   }
   ```
 - See Also: ``prepare()``, ``success()``, ``warning()``, ``error()``, ``info()``

 */
public struct SeamHaptics {
    /**
     Primes the system haptic generator to reduce first‑tap latency.

     Call shortly before you expect to trigger a haptic (e.g., in `onAppear`
     of a button or before starting an unlock flow).

     - Effects: Warms up feedback generators for snappier subsequent calls.
     - Availability: iOS 10+ (no‑op where UIKit is unavailable).
     - Threading: Main thread.
     - Example:
       ```swift
       .onAppear { SeamHaptics.prepare() }
       ```
     */
    public static func prepare() {
#if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().prepare()
        }
#endif
    }
    /**
     Triggers the system **success** notification haptic.

     - Effects: Short affirmative feedback.
     - Availability: iOS 10+ (no‑op where UIKit is unavailable).
     - Example: `SeamHaptics.success()`
     */
    public static func success() {
#if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
#endif
    }

    /**
     Triggers the system **warning** notification haptic.

     - Effects: Emphasized warning feedback.
     - Availability: iOS 10+ (no‑op where UIKit is unavailable).
     - Example: `SeamHaptics.warning()`
     */
    public static func warning() {
#if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
#endif
    }

    /**
     Triggers the system **error** notification haptic.

     - Effects: Strong error feedback.
     - Availability: iOS 10+ (no‑op where UIKit is unavailable).
     - Example: `SeamHaptics.error()`
     */
    public static func error() {
#if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
#endif
    }

    /**
     Triggers a light **impact** haptic suitable for informational cues.

     - Effects: Subtle tap using `UIImpactFeedbackGenerator(style: .light)`.
     - Availability: iOS 10+ (no‑op where UIKit is unavailable).
     - Example: `SeamHaptics.info()`
     */
    public static func info() {
#if canImport(UIKit)
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
#endif
    }
}
