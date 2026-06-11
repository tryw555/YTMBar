import AppKit
import QuartzCore

final class MarqueeLabel: NSView {
    var text: String = "" {
        didSet {
            guard text != oldValue else { return }

            label.stringValue = text
            animationSignature = nil
            needsLayout = true
        }
    }

    private let label = NSTextField(labelWithString: "")
    private let fadeMask = CAGradientLayer()
    private var animationSignature: String?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func layout() {
        super.layout()

        positionLabel()
        updateAnimation()
        updateFadeMask()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.masksToBounds = true
        fadeMask.startPoint = CGPoint(x: 0, y: 0.5)
        fadeMask.endPoint = CGPoint(x: 1, y: 0.5)

        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .labelColor
        label.lineBreakMode = .byClipping
        label.maximumNumberOfLines = 1
        label.isEditable = false
        label.isSelectable = false
        label.wantsLayer = true
        addSubview(label)
    }

    private func updateFadeMask() {
        let shouldFade = label.intrinsicContentSize.width > bounds.width && bounds.width > 0

        guard shouldFade else {
            layer?.mask = nil
            return
        }

        fadeMask.frame = bounds
        fadeMask.colors = [
            NSColor.clear.cgColor,
            NSColor.black.cgColor,
            NSColor.black.cgColor,
            NSColor.clear.cgColor
        ]
        fadeMask.locations = [0, 0.12, 0.88, 1]
        layer?.mask = fadeMask
    }

    private func positionLabel() {
        let labelSize = label.intrinsicContentSize
        let labelWidth = max(labelSize.width, bounds.width)

        label.frame = NSRect(
            x: 0,
            y: floor((bounds.height - labelSize.height) / 2),
            width: labelWidth,
            height: labelSize.height
        )
    }

    private func updateAnimation() {
        let labelWidth = label.intrinsicContentSize.width
        let overflow = max(labelWidth - bounds.width, 0)
        let shouldAnimate = overflow > 1 && bounds.width > 0

        guard shouldAnimate else {
            animationSignature = nil
            label.layer?.removeAnimation(forKey: "ytmbar.marquee.slide")
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            label.layer?.transform = CATransform3DIdentity
            CATransaction.commit()
            return
        }

        let roundedOverflow = Int(overflow.rounded())
        let roundedWidth = Int(bounds.width.rounded())
        let signature = "\(text)|\(roundedWidth)|\(roundedOverflow)"
        let hasAnimation = label.layer?.animation(forKey: "ytmbar.marquee.slide") != nil
        guard signature != animationSignature || !hasAnimation else { return }
        animationSignature = signature

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        label.layer?.transform = CATransform3DIdentity
        CATransaction.commit()

        let travelDuration = min(max(Double(overflow / 13.0), 2.8), 8.0)
        let edgePause = 0.85
        let cycleDuration = travelDuration * 2.0 + edgePause * 2.0
        let firstHoldEnd = NSNumber(value: edgePause / cycleDuration)
        let firstTravelEnd = NSNumber(value: (edgePause + travelDuration) / cycleDuration)
        let secondHoldEnd = NSNumber(value: (edgePause + travelDuration + edgePause) / cycleDuration)

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, 0, -overflow, -overflow, 0]
        animation.keyTimes = [0, firstHoldEnd, firstTravelEnd, secondHoldEnd, 1]
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        animation.duration = cycleDuration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        label.layer?.add(animation, forKey: "ytmbar.marquee.slide")
    }
}
