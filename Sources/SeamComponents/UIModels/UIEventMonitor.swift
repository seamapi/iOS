import SwiftUI
import os

/**
 Public UI event signals emitted by **SeamComponents**.

 These events cover screen appearance/disappearance and discrete user actions.
 They are designed for lightweight telemetry, debugging, and automated testing.

 - Important: **Opt‑in only.** No events are recorded unless the host app
   injects a non‑disabled monitor into the SwiftUI environment (see ``EnvironmentValues/uiEventMonitor``).

 ### Cases
 - ``UIEventMonitorEvent/accessViewAppeared``
 - ``UIEventMonitorEvent/accessViewDisappeared``
 - ``UIEventMonitorEvent/credentialsViewAppeared``
 - ``UIEventMonitorEvent/credentialsViewDisappeared``
 - ``UIEventMonitorEvent/unlockViewAppeared``
 - ``UIEventMonitorEvent/unlockViewDisappeared``
 - ``UIEventMonitorEvent/action(name:)``

 ### Example
 ```swift
 let monitor = UIEventMonitor.console
 SomeView()
   .enableUIEventMonitor(monitor)
 ```
 */
public enum UIEventMonitorEvent: RawRepresentable, Sendable {
    /// Access screen became visible.
    case accessViewAppeared
    /// Access screen is no longer visible.
    case accessViewDisappeared
    /// Credentials list screen became visible.
    case credentialsViewAppeared
    /// Credentials list screen is no longer visible.
    case credentialsViewDisappeared
    /// Unlock screen became visible.
    case unlockViewAppeared
    /// Unlock screen is no longer visible.
    case unlockViewDisappeared
    /// Arbitrary user action marker (e.g., "tap_unlock").
    /// - Parameter name: A short, stable identifier for the action.
    case action(name: String)


    // MARK: RawRepresentable conformance

    public init?(rawValue: String) {
        switch rawValue {
        case "access_view_appeared": self = .accessViewAppeared
        case "access_view_disappeared": self = .accessViewDisappeared
        case "credentials_view_appeared": self = .credentialsViewAppeared
        case "credentials_view_disappeared": self = .credentialsViewDisappeared
        case "unlock_view_appeared": self = .unlockViewAppeared
        case "unlock_view_disappeared": self = .unlockViewDisappeared
        default:
            let actionPrefix = "action_"
            if rawValue.hasPrefix(actionPrefix) {
                self = .action(name: String(rawValue.dropFirst(actionPrefix.count)))
            } else {
                return nil
            }
        }
    }

    public var rawValue: String {
        switch self {
        case .accessViewAppeared:               "access_view_appeared"
        case .accessViewDisappeared:            "access_view_disappeared"
        case .credentialsViewAppeared:          "credentials_view_appeared"
        case .credentialsViewDisappeared:       "credentials_view_disappeared"
        case .unlockViewAppeared:               "unlock_view_appeared"
        case .unlockViewDisappeared:            "unlock_view_disappeared"
        case .action(name: let name):           "action_\(name)"
        }
    }

    public typealias RawValue = String
}

extension UIEventMonitorEvent: CustomStringConvertible {
    /// Human‑readable telemetry label for this event.
    public var description: String {
        switch self {
        case .accessViewAppeared:          return "screen:access appear"
        case .accessViewDisappeared:       return "screen:access disappear"
        case .credentialsViewAppeared:     return "screen:credentials appear"
        case .credentialsViewDisappeared:  return "screen:credentials disappear"
        case .unlockViewAppeared:          return "screen:unlock appear"
        case .unlockViewDisappeared:       return "screen:unlock disappear"
        case .action(let name):            return "action:\(name)"
        }
    }
}


/**
 A lightweight, opt‑in telemetry sink for **SeamComponents** UI events.

 By default, the monitor **does nothing**. Provide a custom instance or use
 ``UIEventMonitor/console`` and inject it via ``View/enableUIEventMonitor(_:)``
 or the ``EnvironmentValues/uiEventMonitor`` key.

 - Important: **No telemetry is sent** unless you provide a monitor.
 */
public struct UIEventMonitor: Sendable {
    /// Records a single UI event. Provide your own implementation to forward
    /// events to telemetry or logging backends. Called on the main thread.
    public var record: @Sendable (UIEventMonitorEvent) -> Void

    /**
     Creates a monitor with a recording closure.

     - Parameter record: A closure invoked for each UI event.
     */
    public init(record: @escaping @Sendable (UIEventMonitorEvent) -> Void) {
        self.record = record
    }

    /// A monitor that drops all events. This is the **default** environment value.
    public static let disabled = UIEventMonitor { _ in }
    /**
     Convenience monitor that logs events using ``os/Logger`` at `.info`.

     - Tip: Useful during development and QA.
     */
    public static let console: UIEventMonitor = {
        let logger = Logger(subsystem: "UIEventMonitor", category: "UIEvent")
        return UIEventMonitor { event in
            logger.info("\(event.description, privacy: .public)")
        }
    }()
}

// MARK: - SwiftUI Environment

private struct UIEventMonitorKey: EnvironmentKey {
    static let defaultValue: UIEventMonitor = .disabled
}

public extension EnvironmentValues {
    /**
     An environment value that controls where SeamComponents send UI events.

     - Default: ``UIEventMonitor/disabled``
     - SeeAlso: ``View/enableUIEventMonitor(_:)``
     */
    var uiEventMonitor: UIEventMonitor {
        get { self[UIEventMonitorKey.self] }
        set { self[UIEventMonitorKey.self] = newValue }
    }
}

public extension View {
    /**
     Injects a ``UIEventMonitor`` to receive SeamComponents UI events.

     Equivalent to:
     ```swift
     .environment(\.uiEventMonitor, client)
     ```

     - Parameter client: The monitor that will receive events.
     - Returns: A view configured to forward events to `client`.
     */
    @inlinable func enableUIEventMonitor(_ client: UIEventMonitor) -> some View {
        environment(\.uiEventMonitor, client)
    }
}

/**
 A view modifier that emits an `appeared` event once when the modified view
 first appears, and a corresponding `disappeared` event when it goes away.

 Use via ``View/monitorScreen(appeared:disappeared:)``.
 */
public struct UIEventMonitorAppearance: ViewModifier {
    @Environment(\.uiEventMonitor) private var monitor
    private let appeared: UIEventMonitorEvent
    private let disappeared: UIEventMonitorEvent

    @State private var hasAppeared = false

    /**
     Creates a screen appearance monitor.

     - Parameters:
       - appeared: Event to record on first appearance.
       - disappeared: Event to record on first disappearance.
     */
    public init(appeared: UIEventMonitorEvent, disappeared: UIEventMonitorEvent) {
        self.appeared = appeared
        self.disappeared = disappeared
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    monitor.record(appeared)
                }
            }
            .onDisappear {
                if hasAppeared {
                    hasAppeared = false
                    monitor.record(disappeared)
                }
            }
    }
}

public extension View {
    /**
     Emits the given `appeared` and `disappeared` events as this view enters
     and leaves the view hierarchy (once per lifecycle).

     - Parameters:
       - appeared: Event to record when the view first appears.
       - disappeared: Event to record when the view disappears.
     - Returns: A view that records appearance events.
     */
    @inlinable func monitorScreen(appeared: UIEventMonitorEvent, disappeared: UIEventMonitorEvent) -> some View {
        modifier(UIEventMonitorAppearance(appeared: appeared, disappeared: disappeared))
    }
}

public extension UIEventMonitor {
    /**
     Records a user action with a simple name (e.g., "tap_unlock").

     - Parameter name: A short, stable identifier for the action.
     - SeeAlso: ``UIEventMonitorEvent/action(name:)``
     */
    @inlinable func action(_ name: String) {
        record(.action(name: name))
    }
}

#if DEBUG
/**
 An in‑memory UI event recorder for tests and Xcode previews.

 - Note: Available only in DEBUG builds.
 */
public actor UIEventMonitorTestRecorder {
    /// Recorded events in arrival order.
    public private(set) var events: [UIEventMonitorEvent] = []

    /// Creates an empty recorder.
    public init() {}

    /**
     Returns a ``UIEventMonitor`` whose `record` appends to this recorder.

     - Returns: A monitor suitable for previews and unit tests.
     */
    public func client() -> UIEventMonitor {
        UIEventMonitor { [weak self] event in
            Task { await self?.append(event) }
        }
    }

    /**
     Appends an event to the recorder.

     - Parameter event: The event to record.
     */
    public func append(_ event: UIEventMonitorEvent) {
        events.append(event)
    }

    /// Removes all recorded events.
    public func reset() { events.removeAll() }
}
#endif
