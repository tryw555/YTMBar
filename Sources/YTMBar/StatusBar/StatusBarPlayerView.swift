import AppKit

final class StatusBarPlayerView: NSView {
    var onPrevious: (() -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onOpenPanel: ((NSView) -> Void)?
    var onHoverBegan: ((NSView) -> Void)?
    var onHoverEnded: (() -> Void)?
    var onModeSelected: ((PlayerDisplayMode) -> Void)?
    var onQuit: (() -> Void)?

    private let mainStack = NSStackView()
    private let artworkView = CDArtworkView(frame: NSRect(x: 0, y: 0, width: 22, height: 22))
    private let artistLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let marqueeLabel = MarqueeLabel()
    private let previousButton = IconButton(symbolName: "backward.fill", accessibilityLabel: "Previous")
    private let playPauseButton = IconButton(symbolName: "play.fill", accessibilityLabel: "Play or Pause")
    private let nextButton = IconButton(symbolName: "forward.fill", accessibilityLabel: "Next")

    private var artistWidthConstraint: NSLayoutConstraint?
    private var titleWidthConstraint: NSLayoutConstraint?
    private var marqueeWidthConstraint: NSLayoutConstraint?
    private var trackingArea: NSTrackingArea?
    private var mode: PlayerDisplayMode = .long
    private var playbackState: PlaybackState = .waiting

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildView()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverBegan?(self)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverEnded?()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if triggerControlIfNeeded(at: point) {
            return
        }

        if contains(point, in: artworkView) || contains(point, in: artistLabel) || contains(point, in: titleLabel) || contains(point, in: marqueeLabel) {
            onOpenPanel?(self)
            return
        }

        super.mouseDown(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        showContextMenu()
    }

    func apply(mode: PlayerDisplayMode) {
        self.mode = mode

        artistLabel.isHidden = mode != .long
        titleLabel.isHidden = mode != .long
        marqueeLabel.isHidden = mode != .medium

        switch mode {
        case .long:
            artistWidthConstraint?.constant = 86
            titleWidthConstraint?.constant = 126
            marqueeWidthConstraint?.constant = 0
        case .medium:
            artistWidthConstraint?.constant = 0
            titleWidthConstraint?.constant = 0
            marqueeWidthConstraint?.constant = 126
        case .compact:
            artistWidthConstraint?.constant = 0
            titleWidthConstraint?.constant = 0
            marqueeWidthConstraint?.constant = 0
        }

        needsLayout = true
    }

    func update(state: PlaybackState, artwork: NSImage?) {
        playbackState = state

        artistLabel.stringValue = state.artist
        titleLabel.stringValue = state.title
        marqueeLabel.text = "\(state.title) - \(state.artist)"
        artworkView.artwork = artwork
        artworkView.isPlaying = state.isPlaying

        let playSymbol = state.isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setSymbolName(playSymbol)
    }

    private func buildView() {
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        mainStack.orientation = .horizontal
        mainStack.alignment = .centerY
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        artworkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: 22),
            artworkView.heightAnchor.constraint(equalToConstant: 22)
        ])

        configure(label: artistLabel, font: .systemFont(ofSize: 10, weight: .regular), color: .secondaryLabelColor)
        configure(label: titleLabel, font: .systemFont(ofSize: 11, weight: .semibold), color: .labelColor)

        artistWidthConstraint = artistLabel.widthAnchor.constraint(equalToConstant: 86)
        titleWidthConstraint = titleLabel.widthAnchor.constraint(equalToConstant: 126)
        artistWidthConstraint?.isActive = true
        titleWidthConstraint?.isActive = true

        marqueeLabel.translatesAutoresizingMaskIntoConstraints = false
        marqueeWidthConstraint = marqueeLabel.widthAnchor.constraint(equalToConstant: 126)
        marqueeWidthConstraint?.isActive = true

        previousButton.target = self
        previousButton.action = #selector(previousTapped)
        playPauseButton.target = self
        playPauseButton.action = #selector(playPauseTapped)
        nextButton.target = self
        nextButton.action = #selector(nextTapped)

        mainStack.addArrangedSubview(artworkView)
        mainStack.addArrangedSubview(artistLabel)
        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(marqueeLabel)
        mainStack.addArrangedSubview(previousButton)
        mainStack.addArrangedSubview(playPauseButton)
        mainStack.addArrangedSubview(nextButton)

        apply(mode: .long)
        update(state: .waiting, artwork: nil)
    }

    private func configure(label: NSTextField, font: NSFont, color: NSColor) {
        label.font = font
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func showContextMenu() {
        let menu = NSMenu()

        for displayMode in PlayerDisplayMode.allCases {
            let item = NSMenuItem(title: displayMode.menuTitle, action: #selector(modeMenuItemTapped(_:)), keyEquivalent: "")
            item.target = self
            item.tag = displayMode.rawValue
            item.state = mode == displayMode ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let openItem = NSMenuItem(title: "Open YouTube Music", action: #selector(openPanelTapped), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let quitItem = NSMenuItem(title: "Quit YTMBar", action: #selector(quitTapped), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: bounds.midX, y: bounds.minY), in: self)
    }

    private func contains(_ point: NSPoint, in view: NSView) -> Bool {
        convert(view.bounds, from: view).contains(point)
    }

    private func contains(_ point: NSPoint, in view: NSView, horizontalPadding: CGFloat, verticalPadding: CGFloat) -> Bool {
        convert(view.bounds, from: view)
            .insetBy(dx: -horizontalPadding, dy: -verticalPadding)
            .contains(point)
    }

    private func triggerControlIfNeeded(at point: NSPoint) -> Bool {
        if contains(point, in: previousButton, horizontalPadding: 4, verticalPadding: 3) {
            previousButton.flashSelection()
            onPrevious?()
            return true
        }

        if contains(point, in: playPauseButton, horizontalPadding: 4, verticalPadding: 3) {
            playPauseButton.flashSelection()
            onTogglePlayPause?()
            return true
        }

        if contains(point, in: nextButton, horizontalPadding: 4, verticalPadding: 3) {
            nextButton.flashSelection()
            onNext?()
            return true
        }

        return false
    }

    @objc private func previousTapped() {
        onPrevious?()
    }

    @objc private func playPauseTapped() {
        onTogglePlayPause?()
    }

    @objc private func nextTapped() {
        onNext?()
    }

    @objc private func openPanelTapped() {
        onOpenPanel?(self)
    }

    @objc private func quitTapped() {
        onQuit?()
    }

    @objc private func modeMenuItemTapped(_ sender: NSMenuItem) {
        guard let mode = PlayerDisplayMode(rawValue: sender.tag) else { return }
        onModeSelected?(mode)
    }
}
