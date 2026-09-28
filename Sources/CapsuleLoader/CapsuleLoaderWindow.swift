import UIKit

/// Sits above the app without becoming the key window, so the keyboard and
/// status bar keep their current owner.
final class CapsuleLoaderWindow: UIWindow {
    var blocksInteraction = true

    override var canBecomeKey: Bool { false }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard blocksInteraction else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// Lets the app's Info.plist decide which orientations the loader follows.
final class CapsuleLoaderRootViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
}
