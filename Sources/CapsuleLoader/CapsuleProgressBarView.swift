import UIKit

/// Capsule progress bar modeled on the macOS determinate and indeterminate progress indicator.
///
/// Leave ``progress`` at `nil` and the bar slides across the track, the same idea as a
/// Finder copy or a macOS pane that is still working. Set ``progress`` from `0` to `1`
/// when you know how far along the work is.
public final class CapsuleProgressBarView: UIView {
    /// Color of the moving fill. `nil` uses the system blue accent.
    public var indicatorColor: UIColor? {
        didSet { applyColors() }
    }

    private let trackView = UIView()
    private let fillView = UIView()
    private var storedProgress: CGFloat?
    private var laidOutBounds: CGRect = .null

    /// `nil` plays the indeterminate slide. A value from 0 to 1 fills the track from the left.
    public var progress: CGFloat? {
        get { storedProgress }
        set { setProgress(newValue, animated: true) }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 6)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        trackView.frame = bounds
        let radius = bounds.height / 2
        trackView.layer.cornerRadius = radius
        fillView.layer.cornerRadius = radius

        guard bounds != laidOutBounds else { return }
        laidOutBounds = bounds
        if storedProgress == nil {
            fillView.layer.removeAnimation(forKey: "travel")
        }
        render(animated: false)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            fillView.layer.removeAnimation(forKey: "travel")
            return
        }
        laidOutBounds = .null
        setNeedsLayout()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyColors()
    }

    /// Switches the bar back to the sliding indeterminate animation.
    public func startAnimating() {
        setProgress(nil, animated: false)
    }

    /// Holds the fill where it is and stops the slide.
    public func stopAnimating() {
        fillView.layer.removeAnimation(forKey: "travel")
    }

    /// Updates how full the bar is.
    ///
    /// Pass `nil` to go back to the indeterminate slide. Values outside 0...1 are clamped.
    public func setProgress(_ progress: CGFloat?, animated: Bool) {
        let resolved = progress.map { min(1, max(0, $0)) }
        guard resolved != storedProgress else { return }
        storedProgress = resolved
        accessibilityValue = resolved.map { "\(Int(($0 * 100).rounded())) percent" }
        render(animated: animated && window != nil)
    }

    private func configure() {
        isOpaque = false
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = "Progress"
        accessibilityTraits = .updatesFrequently

        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        trackView.isUserInteractionEnabled = false
        fillView.isUserInteractionEnabled = false
        fillView.clipsToBounds = true
        trackView.clipsToBounds = true
        addSubview(trackView)
        trackView.addSubview(fillView)
        applyColors()
    }

    private func applyColors() {
        trackView.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.16)
                : UIColor.black.withAlphaComponent(0.1)
        }
        fillView.backgroundColor = indicatorColor ?? .systemBlue
    }

    private func render(animated: Bool) {
        let width = bounds.width
        let height = bounds.height
        guard width > 1, height > 0 else { return }

        if let storedProgress {
            fillView.layer.removeAnimation(forKey: "travel")
            let frame = CGRect(x: 0, y: 0, width: width * storedProgress, height: height)
            if animated {
                UIView.animate(
                    withDuration: 0.35,
                    delay: 0,
                    options: [.curveEaseInOut, .beginFromCurrentState]
                ) {
                    self.fillView.frame = frame
                }
            } else {
                fillView.frame = frame
            }
        } else if fillView.layer.animation(forKey: "travel") == nil {
            installTravelAnimation(width: width, height: height)
        }
    }

    /// The fill grows as it leaves the left edge, then shrinks as it exits on the right.
    private func installTravelAnimation(width: CGFloat, height: CGFloat) {
        let restingWidth = height
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillView.bounds = CGRect(x: 0, y: 0, width: restingWidth, height: height)
        fillView.layer.position = CGPoint(x: 0, y: height / 2)
        CATransaction.commit()

        let maxWidth = max(height, width * 0.58)
        let widthAnimation = CAKeyframeAnimation(keyPath: "bounds.size.width")
        widthAnimation.values = [restingWidth, maxWidth, restingWidth]
        widthAnimation.keyTimes = [0, 0.45, 1]

        let positionAnimation = CAKeyframeAnimation(keyPath: "position.x")
        positionAnimation.values = [0, width * 0.55, width]
        positionAnimation.keyTimes = [0, 0.45, 1]

        let ease = CAMediaTimingFunction(name: .easeInEaseOut)
        widthAnimation.timingFunctions = [ease, ease]
        positionAnimation.timingFunctions = [ease, ease]

        let group = CAAnimationGroup()
        group.animations = [widthAnimation, positionAnimation]
        group.duration = 1.3
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        fillView.layer.add(group, forKey: "travel")
    }
}
