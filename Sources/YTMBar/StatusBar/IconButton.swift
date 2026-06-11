import AppKit

final class IconButton: NSButton {
    private var symbolName: String
    private var hoverTrackingArea: NSTrackingArea?
    private var isHovering = false {
        didSet {
            needsDisplay = true
        }
    }

    override var isHighlighted: Bool {
        didSet {
            needsDisplay = true
        }
    }

    init(symbolName: String, accessibilityLabel: String) {
        self.symbolName = symbolName
        super.init(frame: .zero)

        title = ""
        image = nil
        imagePosition = .noImage
        bezelStyle = .shadowlessSquare
        isBordered = false
        setButtonType(.momentaryChange)
        toolTip = accessibilityLabel
        setAccessibilityLabel(accessibilityLabel)
        focusRingType = .none
        refusesFirstResponder = true
        translatesAutoresizingMaskIntoConstraints = false

        widthAnchor.constraint(equalToConstant: 22).isActive = true
        heightAnchor.constraint(equalToConstant: 22).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }

        isHighlighted = true
        _ = sendAction(action, to: target)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.isHighlighted = false
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        hoverTrackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    override func draw(_ dirtyRect: NSRect) {
        drawBackground()
        drawIcon()
    }

    func setSymbolName(_ symbolName: String) {
        guard self.symbolName != symbolName else { return }
        self.symbolName = symbolName
        needsDisplay = true
    }

    func flashSelection() {
        isHighlighted = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.isHighlighted = false
        }
    }

    private func drawBackground() {
        let alpha: CGFloat

        if isHighlighted {
            alpha = 0.22
        } else if isHovering {
            alpha = 0.10
        } else {
            alpha = 0
        }

        guard alpha > 0 else { return }

        resolvedLabelColor.withAlphaComponent(alpha).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 2), xRadius: 5, yRadius: 5).fill()
    }

    private func drawIcon() {
        let color = resolvedLabelColor.withAlphaComponent(isEnabled ? 0.88 : 0.32)
        color.setFill()

        let iconRect = bounds.insetBy(dx: 5.0, dy: 5.2)

        if symbolName.contains("pause") {
            drawPause(in: iconRect)
        } else if symbolName.contains("backward") {
            drawBackward(in: iconRect)
        } else if symbolName.contains("forward") {
            drawForward(in: iconRect)
        } else {
            drawPlay(in: iconRect)
        }
    }

    private func drawPlay(in rect: NSRect) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX + 1.5, y: rect.minY + 0.4))
        path.line(to: NSPoint(x: rect.maxX - 0.8, y: rect.midY))
        path.line(to: NSPoint(x: rect.minX + 1.5, y: rect.maxY - 0.4))
        path.close()
        path.fill()
    }

    private func drawPause(in rect: NSRect) {
        let barWidth = max(3.0, rect.width * 0.28)
        let gap = max(2.5, rect.width * 0.18)
        let leftX = rect.midX - gap / 2 - barWidth
        let rightX = rect.midX + gap / 2
        let barRect = NSRect(x: leftX, y: rect.minY + 0.2, width: barWidth, height: rect.height - 0.4)
        let secondBarRect = NSRect(x: rightX, y: barRect.minY, width: barWidth, height: barRect.height)

        NSBezierPath(roundedRect: barRect, xRadius: 1.2, yRadius: 1.2).fill()
        NSBezierPath(roundedRect: secondBarRect, xRadius: 1.2, yRadius: 1.2).fill()
    }

    private func drawBackward(in rect: NSRect) {
        let first = NSRect(x: rect.minX, y: rect.minY, width: rect.width * 0.54, height: rect.height)
        let second = NSRect(x: rect.midX - 0.2, y: rect.minY, width: rect.width * 0.54, height: rect.height)
        drawLeftTriangle(in: second)
        drawLeftTriangle(in: first)
    }

    private func drawForward(in rect: NSRect) {
        let first = NSRect(x: rect.minX - 0.1, y: rect.minY, width: rect.width * 0.54, height: rect.height)
        let second = NSRect(x: rect.midX - 0.1, y: rect.minY, width: rect.width * 0.54, height: rect.height)
        drawRightTriangle(in: first)
        drawRightTriangle(in: second)
    }

    private func drawLeftTriangle(in rect: NSRect) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.maxX, y: rect.minY + 0.4))
        path.line(to: NSPoint(x: rect.minX + 0.2, y: rect.midY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - 0.4))
        path.close()
        path.fill()
    }

    private func drawRightTriangle(in rect: NSRect) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX, y: rect.minY + 0.4))
        path.line(to: NSPoint(x: rect.maxX - 0.2, y: rect.midY))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - 0.4))
        path.close()
        path.fill()
    }

    private var resolvedLabelColor: NSColor {
        NSColor.labelColor
    }
}
