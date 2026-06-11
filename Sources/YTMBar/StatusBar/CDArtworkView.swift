import AppKit
import QuartzCore

final class CDArtworkView: NSView {
    private let discLayer = CALayer()
    private var stopSpinWorkItem: DispatchWorkItem?

    var artwork: NSImage? {
        didSet {
            updateDiscImage()
        }
    }

    var isPlaying: Bool = false {
        didSet {
            guard isPlaying != oldValue else { return }

            if isPlaying {
                stopSpinWorkItem?.cancel()
                stopSpinWorkItem = nil
                startSpinning()
            } else {
                scheduleStopSpinning()
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 22, height: 22)
    }

    override func layout() {
        super.layout()
        updateDiscLayerGeometry()
        updateDiscImage()
        ensureSpinMatchesPlayback()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        ensureSpinMatchesPlayback()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.masksToBounds = false

        discLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        discLayer.contentsGravity = .resizeAspect
        discLayer.masksToBounds = false
        layer?.addSublayer(discLayer)

        updateDiscLayerGeometry()
        updateDiscImage()
    }

    private func updateDiscLayerGeometry() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        discLayer.contentsScale = windowScale
        discLayer.bounds = NSRect(origin: .zero, size: bounds.size)
        discLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }

    private func updateDiscImage() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let size = NSSize(width: bounds.width * windowScale, height: bounds.height * windowScale)
        let image = NSImage(size: size)

        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        let outerPath = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
        outerPath.addClip()

        if let artwork {
            artwork.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        } else {
            drawPlaceholder(in: rect)
        }

        NSColor.black.withAlphaComponent(0.18).setStroke()
        outerPath.lineWidth = 1.5
        outerPath.stroke()

        let ringRect = rect.insetBy(dx: rect.width * 0.25, dy: rect.height * 0.25)
        let ring = NSBezierPath(ovalIn: ringRect)
        NSColor.white.withAlphaComponent(0.18).setStroke()
        ring.lineWidth = 1
        ring.stroke()

        let holeRect = rect.insetBy(dx: rect.width * 0.39, dy: rect.height * 0.39)
        let hole = NSBezierPath(ovalIn: holeRect)
        NSColor.windowBackgroundColor.setFill()
        hole.fill()
        NSColor.black.withAlphaComponent(0.22).setStroke()
        hole.lineWidth = 1
        hole.stroke()

        image.unlockFocus()

        discLayer.contents = image
    }

    private func drawPlaceholder(in rect: NSRect) {
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.95, green: 0.16, blue: 0.22, alpha: 1),
            NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.16, alpha: 1),
            NSColor(calibratedRed: 0.08, green: 0.42, blue: 0.52, alpha: 1)
        ])

        gradient?.draw(in: rect, angle: 35)

        NSColor.white.withAlphaComponent(0.22).setStroke()
        for inset in stride(from: rect.width * 0.12, through: rect.width * 0.38, by: rect.width * 0.11) {
            let groove = NSBezierPath(ovalIn: rect.insetBy(dx: inset, dy: inset))
            groove.lineWidth = 0.5
            groove.stroke()
        }
    }

    private func startSpinning() {
        guard discLayer.animation(forKey: "ytmbar.cd.spin") == nil else { return }

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = 4.5
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)

        discLayer.add(animation, forKey: "ytmbar.cd.spin")
    }

    private func scheduleStopSpinning() {
        stopSpinWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !isPlaying else { return }
            stopSpinning()
        }

        stopSpinWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
    }

    private func stopSpinning() {
        stopSpinWorkItem?.cancel()
        stopSpinWorkItem = nil
        discLayer.removeAnimation(forKey: "ytmbar.cd.spin")
        discLayer.transform = CATransform3DIdentity
    }

    private func ensureSpinMatchesPlayback() {
        if isPlaying {
            stopSpinWorkItem?.cancel()
            stopSpinWorkItem = nil
            startSpinning()
        } else if stopSpinWorkItem == nil {
            stopSpinning()
        }
    }

    private var windowScale: CGFloat {
        window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
    }
}
