import Foundation

// MARK: - Human‑readable date formatting

extension DateFormatter {
    /// A shared, locale‑aware formatter for human‑readable dates and times.
    ///
    /// Produces a **medium** date style (e.g., "Apr 21, 2025") and **short** time style
    /// (e.g., "3:45 PM"), with `doesRelativeDateFormatting = true` so recent dates render
    /// as “Today”/“Yesterday” when appropriate.
    ///
    /// - Localization: Uses `Locale.current` and the current calendar/time zone.
    /// - Thread Safety: `DateFormatter` isn’t thread‑safe. Access this shared instance on a single queue
    ///   (typically the main actor) or wrap calls appropriately when used off the main thread.
    ///
    /// - Example:
    /// ```swift
    /// let text = DateFormatter.seamHumanReadable.string(from: Date())
    /// ```
    ///
    /// - SeeAlso: ``Date/seamHumanReadableString``
    public static let seamHumanReadable: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.dateStyle = .medium       // e.g. “Apr 21, 2025”
        fmt.timeStyle = .short        // e.g. “3:45 PM”
        fmt.doesRelativeDateFormatting = true
        return fmt
    }()
}

extension Date {
    /// Returns a human‑readable string for this date using ``DateFormatter/seamHumanReadable``.
    ///
    /// - Returns: A localized string such as "Today, 3:45 PM" or "Apr 21, 2025, 3:45 PM".
    ///
    /// - Example:
    /// ```swift
    /// let label = Date().seamHumanReadableString
    /// ```
    ///
    /// - SeeAlso: ``DateFormatter/seamHumanReadable``
    public var seamHumanReadableString: String {
        DateFormatter.seamHumanReadable.string(from: self)
    }
}
