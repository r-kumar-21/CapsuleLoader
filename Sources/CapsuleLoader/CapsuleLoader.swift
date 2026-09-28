import UIKit

/// A macOS-inspired loading panel for iOS.
///
/// Show it when an API call starts, and hide it when that call finishes.
/// Nested calls are counted: two shows need two hides before the panel goes away.
///
/// ```swift
/// CapsuleLoader.show("Loading")
/// defer { CapsuleLoader.hide() }
/// posts = try await api.posts()
/// ```
///
/// For a single call, ``run(_:style:operation:)`` shows and hides for you:
///
/// ```swift
/// let posts = try await CapsuleLoader.run("Loading") {
///     try await api.posts()
/// }
/// ```
public enum CapsuleLoader {
    /// Which indicator to put in the panel.
    public enum Style: Sendable, Equatable {
        /// The sliding capsule used by Finder and macOS progress bars.
        case bar
        /// The rotating ring used by the macOS activity indicator.
        case spinner
    }

    /// How the full-screen panel sits over your interface.
    public struct Appearance: Sendable, Equatable {
        /// Draws a light dim behind the panel so the screen reads as busy.
        public var dimsBackground: Bool
        /// Swallows touches while the loader is up, so the user cannot start another action.
        public var blocksInteraction: Bool

        public init(dimsBackground: Bool = true, blocksInteraction: Bool = true) {
            self.dimsBackground = dimsBackground
            self.blocksInteraction = blocksInteraction
        }

        public static let standard = Appearance()
    }

    /// Shows the loader over the app.
    ///
    /// Safe to call from a background queue. If you are already on the main thread,
    /// the panel appears before this method returns.
    ///
    /// - Parameters:
    ///   - message: Optional line of text under the indicator, such as `"Saving"`.
    ///   - style: Pass a style to change the indicator. While a loader is already visible,
    ///     omitting this keeps the current style.
    public static func show(_ message: String? = nil, style: Style? = nil) {
        let message = message
        let style = style
        runOnMain {
            CapsuleLoaderController.shared.show(message: message, style: style, host: nil)
        }
    }

    /// Shows the loader inside a specific view, covering that view only.
    ///
    /// Call this from the main thread. Useful when one screen is loading and the rest of the app should stay usable.
    @MainActor
    public static func show(_ message: String? = nil, style: Style? = nil, in host: UIView) {
        CapsuleLoaderController.shared.show(message: message, style: style, host: host)
    }

    /// Hides one matching ``show``. The panel stays up while other shows are still open.
    public static func hide() {
        runOnMain {
            CapsuleLoaderController.shared.hide()
        }
    }

    /// Hides the loader immediately, even if ``show`` was called more than once.
    public static func hideAll() {
        runOnMain {
            CapsuleLoaderController.shared.hideAll()
        }
    }

    /// Moves the bar to a known fraction, from 0 to 1.
    ///
    /// Use this with ``Style/bar`` when a download or import can report progress.
    /// Pass `nil` to return to the sliding animation. Values outside 0...1 are clamped.
    public static func setProgress(_ progress: Double?, animated: Bool = true) {
        runOnMain {
            CapsuleLoaderController.shared.setProgress(progress, animated: animated)
        }
    }

    /// Changes dimming and touch blocking. Takes effect immediately if the loader is visible.
    public static func configure(_ appearance: Appearance) {
        runOnMain {
            let controller = CapsuleLoaderController.shared
            controller.dimsBackground = appearance.dimsBackground
            controller.blocksInteraction = appearance.blocksInteraction
            controller.refreshAppearance()
        }
    }

    /// Tints the bar or spinner. Pass `nil` to restore the automatic system colors.
    public static func setIndicatorColor(_ color: UIColor?) {
        let color = color
        runOnMain {
            let controller = CapsuleLoaderController.shared
            controller.indicatorColor = color
            controller.refreshAppearance()
        }
    }

    /// Shows the loader, runs an API call, then hides it — including when the call throws.
    ///
    /// ```swift
    /// let user = try await CapsuleLoader.run("Signing in") {
    ///     try await auth.signIn(email: email, password: password)
    /// }
    /// ```
    @MainActor
    public static func run<T: Sendable>(
        _ message: String? = nil,
        style: Style? = nil,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        show(message, style: style)
        defer { hide() }
        return try await operation()
    }
}

extension CapsuleLoader {
    static func runOnMain(_ body: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated(body)
            }
        }
    }
}
