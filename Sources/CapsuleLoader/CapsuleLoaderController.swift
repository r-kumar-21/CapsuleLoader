import UIKit

@MainActor
final class CapsuleLoaderController {
    static let shared = CapsuleLoaderController()

    var dimsBackground = true
    var blocksInteraction = true
    var indicatorColor: UIColor?

    private var session = CapsuleLoaderSession()
    private var style: CapsuleLoader.Style = .bar
    private var message: String?
    private var progress: Double?
    private var dismissGeneration = 0
    private var sceneRetryCount = 0
    private var needsAnnouncement = false
    private var overlay: CapsuleLoaderOverlayView?
    private var loaderWindow: CapsuleLoaderWindow?
    private weak var hostView: UIView?

    var isVisible: Bool { session.isVisible }

    func show(message: String?, style: CapsuleLoader.Style?, host: UIView?) {
        let becomingVisible = session.show()
        if becomingVisible {
            self.progress = nil
            self.style = style ?? .bar
            self.message = message
        } else {
            if let style { self.style = style }
            if let message { self.message = message }
        }
        hostView = host
        if becomingVisible {
            needsAnnouncement = true
        }
        present()
    }

    func hide() {
        guard session.hide() else { return }
        progress = nil
        dismiss()
    }

    func hideAll() {
        guard session.hideAll() || overlay != nil else { return }
        progress = nil
        dismiss()
    }

    func setProgress(_ progress: Double?, animated: Bool) {
        self.progress = progress
        overlay?.setProgress(progress, animated: animated)
    }

    func refreshAppearance() {
        overlay?.update(
            message: message,
            style: style,
            progress: progress,
            indicatorColor: indicatorColor,
            dimsBackground: dimsBackground,
            blocksInteraction: blocksInteraction
        )
        loaderWindow?.blocksInteraction = blocksInteraction
    }

    private func present() {
        dismissGeneration += 1
        guard let view = attachOverlay() else {
            scheduleSceneRetry()
            return
        }
        sceneRetryCount = 0
        matchAppInterfaceStyle()
        view.update(
            message: message,
            style: style,
            progress: progress,
            indicatorColor: indicatorColor,
            dimsBackground: dimsBackground,
            blocksInteraction: blocksInteraction
        )
        loaderWindow?.blocksInteraction = blocksInteraction
        view.present(animated: true)
        guard needsAnnouncement else { return }
        needsAnnouncement = false
        UIAccessibility.post(notification: .announcement, argument: message ?? "Loading")
    }

    private func scheduleSceneRetry() {
        guard sceneRetryCount < 8, session.isVisible else { return }
        sceneRetryCount += 1
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            guard self.session.isVisible else { return }
            self.present()
        }
    }

    private func matchAppInterfaceStyle() {
        guard let loaderWindow, let scene = loaderWindow.windowScene else { return }
        let appWindow = scene.windows.first { $0 !== loaderWindow && $0.isKeyWindow }
        loaderWindow.overrideUserInterfaceStyle = appWindow?.overrideUserInterfaceStyle ?? .unspecified
    }

    private func dismiss() {
        dismissGeneration += 1
        let generation = dismissGeneration
        guard let overlay else { return }
        overlay.dismiss(animated: true) { [weak self] in
            guard let self, self.dismissGeneration == generation else { return }
            self.teardown()
        }
    }

    private func attachOverlay() -> CapsuleLoaderOverlayView? {
        if let hostView {
            teardownWindow()
            let view = overlay ?? CapsuleLoaderOverlayView()
            if view.superview !== hostView {
                view.removeFromSuperview()
                view.translatesAutoresizingMaskIntoConstraints = false
                hostView.addSubview(view)
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
                    view.topAnchor.constraint(equalTo: hostView.topAnchor),
                    view.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
                ])
            }
            hostView.bringSubviewToFront(view)
            overlay = view
            return view
        }

        if let overlay, loaderWindow != nil {
            return overlay
        }

        guard activeScene() != nil else { return nil }
        overlay?.removeFromSuperview()
        let view = CapsuleLoaderOverlayView()
        view.translatesAutoresizingMaskIntoConstraints = false
        guard let window = makeWindow(hosting: view) else { return nil }
        loaderWindow = window
        overlay = view
        return view
    }

    private func makeWindow(hosting overlay: CapsuleLoaderOverlayView) -> CapsuleLoaderWindow? {
        guard let scene = activeScene() else { return nil }
        let window = CapsuleLoaderWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.windowLevel = .normal + 1
        window.blocksInteraction = blocksInteraction
        if let appWindow = scene.windows.first(where: { $0 !== window && $0.isKeyWindow }) {
            window.overrideUserInterfaceStyle = appWindow.overrideUserInterfaceStyle
        }

        let root = CapsuleLoaderRootViewController()
        root.view.backgroundColor = .clear
        window.rootViewController = root
        root.view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: root.view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: root.view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: root.view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: root.view.bottomAnchor),
        ])
        window.isHidden = false
        return window
    }

    private func activeScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }

    private func teardown() {
        overlay?.removeFromSuperview()
        overlay = nil
        teardownWindow()
        hostView = nil
        needsAnnouncement = false
    }

    private func teardownWindow() {
        loaderWindow?.isHidden = true
        loaderWindow?.rootViewController = nil
        loaderWindow = nil
    }
}
