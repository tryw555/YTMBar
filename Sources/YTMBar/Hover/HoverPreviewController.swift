import AppKit

final class HoverPreviewController {
    private let popover = NSPopover()
    private let contentController = HoverPreviewViewController()
    private var closeTimer: Timer?

    init() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 282, height: 96)
        popover.contentViewController = contentController
    }

    func show(from anchorView: NSView, state: PlaybackState, artwork: NSImage?) {
        closeTimer?.invalidate()
        contentController.update(state: state, artwork: artwork)

        if popover.isShown {
            return
        }

        popover.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .minY)
    }

    func scheduleClose() {
        closeTimer?.invalidate()
        closeTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            self?.popover.performClose(nil)
        }
    }
}

private final class HoverPreviewViewController: NSViewController {
    private let container = NSVisualEffectView()
    private let artworkView = CDArtworkView(frame: NSRect(x: 0, y: 0, width: 58, height: 58))
    private let titleLabel = NSTextField(labelWithString: "")
    private let artistLabel = NSTextField(labelWithString: "")

    override func loadView() {
        container.material = .hudWindow
        container.blendingMode = .behindWindow
        container.state = .active
        container.wantsLayer = true
        container.layer?.cornerRadius = 8

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        artworkView.translatesAutoresizingMaskIntoConstraints = false
        artworkView.widthAnchor.constraint(equalToConstant: 58).isActive = true
        artworkView.heightAnchor.constraint(equalToConstant: 58).isActive = true
        stack.addArrangedSubview(artworkView)

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        stack.addArrangedSubview(textStack)

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 2

        artistLabel.font = .systemFont(ofSize: 12, weight: .regular)
        artistLabel.textColor = .secondaryLabelColor
        artistLabel.lineBreakMode = .byTruncatingTail

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(artistLabel)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        view = container
    }

    func update(state: PlaybackState, artwork: NSImage?) {
        titleLabel.stringValue = state.title
        artistLabel.stringValue = state.artist
        artworkView.artwork = artwork
        artworkView.isPlaying = state.isPlaying
    }
}
