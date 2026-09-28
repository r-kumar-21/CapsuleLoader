import UIKit

/// Circular activity indicator modeled on the macOS spinning progress indicator.
///
/// A soft tail fades into a solid head, and the ring rotates at a steady pace.
/// Drop it into a view, or use ``CapsuleSpinner`` from SwiftUI. It starts spinning
/// when it is on screen.
public final class CapsuleSpinnerView: UIView {
    /// Color of the head of the ring. `nil` uses the label color, so it follows light and dark mode.
    public var indicatorColor: UIColor? {
        didSet { applyColors() }
    }

    /// Set to `false` to freeze the ring in place.
    public var isAnimating = true {
        didSet { syncAnimation() }
    }

    private let gradientLayer = CAGradientLayer()
    private let ringMask = CAShapeLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds

        let scale = max(traitCollection.displayScale, 1)
        gradientLayer.contentsScale = scale
        ringMask.contentsScale = scale

        let lineWidth = max(2.25, min(bounds.width, bounds.height) * 0.075)
        let radius = max(0, (min(bounds.width, bounds.height) - lineWidth) / 2)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        )
        ringMask.path = path.cgPath
        ringMask.lineWidth = lineWidth
        syncAnimation()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        syncAnimation()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyColors()
    }

    /// Starts the rotation. The ring also starts on its own when added to a window.
    public func startAnimating() {
        isAnimating = true
    }

    /// Stops the rotation.
    public func stopAnimating() {
        isAnimating = false
    }

    private func configure() {
        isOpaque = false
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = "Loading"
        accessibilityTraits = .updatesFrequently

        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        layer.addSublayer(gradientLayer)

        ringMask.fillColor = UIColor.clear.cgColor
        ringMask.strokeColor = UIColor.black.cgColor
        ringMask.lineCap = .butt
        gradientLayer.mask = ringMask

        applyColors()
    }

    private func applyColors() {
        let color = indicatorColor ?? .label
        gradientLayer.colors = [
            color.withAlphaComponent(0).cgColor,
            color.withAlphaComponent(0.12).cgColor,
            color.withAlphaComponent(0.45).cgColor,
            color.cgColor,
        ]
        gradientLayer.locations = [0, 0.28, 0.62, 1]
    }

    private func syncAnimation() {
        let shouldSpin = isAnimating && window != nil && !isHidden && bounds.width > 0
        if shouldSpin {
            guard gradientLayer.animation(forKey: "spin") == nil else { return }
            let spin = CABasicAnimation(keyPath: "transform.rotation.z")
            spin.fromValue = 0
            spin.toValue = CGFloat.pi * 2
            spin.duration = 0.95
            spin.repeatCount = .infinity
            spin.timingFunction = CAMediaTimingFunction(name: .linear)
            spin.isRemovedOnCompletion = false
            gradientLayer.add(spin, forKey: "spin")
        } else {
            gradientLayer.removeAnimation(forKey: "spin")
        }
    }
}
