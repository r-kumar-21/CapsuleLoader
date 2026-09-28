import UIKit

/// Full-screen dim plus the centered loader panel. Shared by the window loader and SwiftUI.
final class CapsuleLoaderOverlayView: UIView {
    private let dimView = UIView()
    private let cardView = UIView()
    private let materialView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let stackView = UIStackView()
    private let spinnerView = CapsuleSpinnerView()
    private let barView = CapsuleProgressBarView()
    private let messageLabel = UILabel()
    private var preferredWidth: NSLayoutConstraint!

    private let cardCornerRadius: CGFloat = 22

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cardCornerRadius
        ).cgPath
        let scale = max(traitCollection.displayScale, 1)
        materialView.layer.borderWidth = 1 / scale
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyChromeColors()
    }

    func update(
        message: String?,
        style: CapsuleLoader.Style,
        progress: Double?,
        indicatorColor: UIColor?,
        dimsBackground: Bool,
        blocksInteraction: Bool
    ) {
        let text = message.flatMap { value -> String? in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        let compactSpinner = style == .spinner && text == nil
        materialView.contentView.layoutMargins = compactSpinner
            ? UIEdgeInsets(top: 28, left: 28, bottom: 28, right: 28)
            : UIEdgeInsets(top: 18, left: 22, bottom: 18, right: 22)
        preferredWidth.constant = compactSpinner ? 88 : 208

        UIView.performWithoutAnimation {
            spinnerView.isHidden = style != .spinner
            barView.isHidden = style != .bar
            messageLabel.isHidden = text == nil
            messageLabel.text = text
            layoutIfNeeded()
        }

        spinnerView.isAnimating = style == .spinner
        spinnerView.indicatorColor = indicatorColor
        barView.indicatorColor = indicatorColor
        if style == .bar {
            barView.setProgress(progress.map { CGFloat($0) }, animated: false)
        } else {
            barView.stopAnimating()
        }

        dimView.alpha = dimsBackground ? 1 : 0
        isUserInteractionEnabled = blocksInteraction

        accessibilityViewIsModal = blocksInteraction
        accessibilityLabel = text ?? "Loading"
        spinnerView.isAccessibilityElement = false
        barView.isAccessibilityElement = false
        messageLabel.isAccessibilityElement = false
    }

    func setProgress(_ progress: Double?, animated: Bool) {
        barView.setProgress(progress.map { CGFloat($0) }, animated: animated)
    }

    func present(animated: Bool) {
        let shouldAnimate = animated && alpha < 0.99
        if shouldAnimate {
            cardView.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }
        let animations = {
            self.alpha = 1
            self.cardView.transform = .identity
        }
        if shouldAnimate {
            UIView.animate(
                withDuration: 0.38,
                delay: 0,
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.35,
                options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }
    }

    func dismiss(animated: Bool, completion: @escaping () -> Void) {
        let animations = {
            self.alpha = 0
            self.cardView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
        guard animated else {
            animations()
            completion()
            return
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: animations) { _ in
            completion()
        }
    }

    private func configure() {
        isOpaque = false
        backgroundColor = .clear
        alpha = 0
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .clear
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 12)
        cardView.layer.shadowRadius = 28
        addSubview(cardView)

        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.clipsToBounds = true
        materialView.layer.cornerRadius = cardCornerRadius
        materialView.layer.cornerCurve = .continuous
        materialView.contentView.insetsLayoutMarginsFromSafeArea = false
        cardView.addSubview(materialView)

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false
        materialView.contentView.addSubview(stackView)

        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        barView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(
            for: .systemFont(ofSize: 13, weight: .medium)
        )
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 3

        stackView.addArrangedSubview(spinnerView)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(barView)

        preferredWidth = cardView.widthAnchor.constraint(equalToConstant: 208)
        preferredWidth.priority = UILayoutPriority(999)

        let margins = materialView.contentView.layoutMarginsGuide
        // Required, with no negative constant, so a zero-width host does not
        // produce an unsatisfiable layout. The preferred width wins when there is room.
        let widthLimit = cardView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor)
        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            preferredWidth,
            widthLimit,

            materialView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            materialView.topAnchor.constraint(equalTo: cardView.topAnchor),
            materialView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: margins.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),

            spinnerView.widthAnchor.constraint(equalToConstant: 32),
            spinnerView.heightAnchor.constraint(equalToConstant: 32),
            barView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            barView.heightAnchor.constraint(equalToConstant: 6),
            messageLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])

        materialView.contentView.layoutMargins = UIEdgeInsets(top: 22, left: 22, bottom: 22, right: 22)
        applyChromeColors()
    }

    private func applyChromeColors() {
        let border = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.14)
                : UIColor.black.withAlphaComponent(0.06)
        }
        materialView.layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
        cardView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.45 : 0.16
    }
}
