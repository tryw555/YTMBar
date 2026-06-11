import AppKit

final class PlayerPanelController: NSObject, PlaybackCommanding {
    var onPlaybackStateChange: ((PlaybackState, NSImage?, Bool) -> Void)?

    private lazy var webController: YouTubeMusicViewController = {
        let controller = YouTubeMusicViewController()
        controller.onPlaybackStateChange = { [weak self] state in
            self?.handlePlaybackStateChange(state)
        }
        return controller
    }()

    private var panel: NSPanel?
    private var latestState: PlaybackState?
    private var currentArtwork: NSImage?
    private var currentArtworkURL: URL?
    private var lastToggleDate = Date.distantPast
    private var lastAnyPlaybackCommand: (desiredState: Bool, date: Date, source: PlaybackCommandSource)?
    private var lastLocalPlaybackCommand: (desiredState: Bool, date: Date)?

    private let toggleDebounceInterval: TimeInterval = 0.22
    private let repeatedCommandInterval: TimeInterval = 0.18
    private let remoteBounceInterval: TimeInterval = 7.0

    override init() {
        super.init()
        webController.loadViewIfNeeded()
    }

    func playPrevious() {
        DiagnosticsLogger.shared.log("Playback command: previous")
        webController.playPrevious()
    }

    func togglePlayPause(source: PlaybackCommandSource) {
        let now = Date()

        if now.timeIntervalSince(lastToggleDate) < toggleDebounceInterval {
            DiagnosticsLogger.shared.log("Ignored duplicate toggle from \(source.rawValue)")
            return
        }

        lastToggleDate = now
        let shouldPlay = !(latestState?.isPlaying ?? false)
        setPlayback(playing: shouldPlay, source: source, now: now)
    }

    func setPlayback(playing shouldPlay: Bool, source: PlaybackCommandSource) {
        setPlayback(playing: shouldPlay, source: source, now: Date())
    }

    func playNext() {
        DiagnosticsLogger.shared.log("Playback command: next")
        webController.playNext()
    }

    private func setPlayback(playing shouldPlay: Bool, source: PlaybackCommandSource, now: Date) {
        if shouldIgnorePlaybackCommand(playing: shouldPlay, source: source, now: now) {
            return
        }

        rememberPlaybackCommand(playing: shouldPlay, source: source, now: now)
        DiagnosticsLogger.shared.log("Playback command: \(shouldPlay ? "play" : "pause") source=\(source.rawValue) current=\(latestState?.isPlaying.description ?? "unknown")")

        if var state = latestState {
            state.isPlaying = shouldPlay
            latestState = state
            emit(state: state, artwork: artworkForImmediateUpdate(state), bypassPauseStabilization: true)
        }

        webController.setPlayback(playing: shouldPlay)
    }

    func togglePlayerPanel(from anchorView: NSView) {
        let panel = makePanelIfNeeded()

        if panel.isVisible {
            panel.orderOut(nil)
            return
        }

        position(panel: panel, near: anchorView)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showPlayerPanelCentered() {
        let panel = makePanelIfNeeded()

        if !panel.isVisible {
            center(panel: panel)
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 760),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "YouTube Music"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = webController
        panel.setContentSize(NSSize(width: 390, height: 760))

        self.panel = panel
        return panel
    }

    private func handlePlaybackStateChange(_ state: PlaybackState) {
        latestState = state
        emit(state: state, artwork: artworkForImmediateUpdate(state), bypassPauseStabilization: false)

        ArtworkLoader.shared.loadArtwork(from: state.artworkURL) { [weak self] artwork in
            guard let self else { return }

            currentArtwork = artwork
            currentArtworkURL = state.artworkURL
            emit(state: state, artwork: artwork, bypassPauseStabilization: false)
        }
    }

    private func emit(state: PlaybackState, artwork: NSImage?, bypassPauseStabilization: Bool) {
        onPlaybackStateChange?(state, artwork, bypassPauseStabilization)
    }

    private func artworkForImmediateUpdate(_ state: PlaybackState) -> NSImage? {
        state.artworkURL == currentArtworkURL ? currentArtwork : nil
    }

    private func shouldIgnorePlaybackCommand(playing shouldPlay: Bool, source: PlaybackCommandSource, now: Date) -> Bool {
        if let lastAnyPlaybackCommand,
           lastAnyPlaybackCommand.desiredState == shouldPlay,
           now.timeIntervalSince(lastAnyPlaybackCommand.date) < repeatedCommandInterval
        {
            DiagnosticsLogger.shared.log("Ignored repeated \(shouldPlay ? "play" : "pause") from \(source.rawValue)")
            return true
        }

        if source == .system,
           let lastLocalPlaybackCommand,
           lastLocalPlaybackCommand.desiredState != shouldPlay,
           now.timeIntervalSince(lastLocalPlaybackCommand.date) < remoteBounceInterval
        {
            DiagnosticsLogger.shared.log("Ignored likely remote bounce: \(shouldPlay ? "play" : "pause") after local \(lastLocalPlaybackCommand.desiredState ? "play" : "pause")")
            return true
        }

        return false
    }

    private func rememberPlaybackCommand(playing shouldPlay: Bool, source: PlaybackCommandSource, now: Date) {
        lastAnyPlaybackCommand = (shouldPlay, now, source)

        if source != .system {
            lastLocalPlaybackCommand = (shouldPlay, now)
        }
    }

    private func position(panel: NSPanel, near anchorView: NSView) {
        let panelSize = panel.frame.size
        let fallbackFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let screenFrame = anchorView.window?.screen?.visibleFrame ?? fallbackFrame
        let anchorScreenRect = screenRect(for: anchorView) ?? NSRect(
            x: screenFrame.midX,
            y: screenFrame.maxY,
            width: 1,
            height: 1
        )

        var origin = NSPoint(
            x: anchorScreenRect.midX - panelSize.width / 2,
            y: anchorScreenRect.minY - panelSize.height - 8
        )

        origin.x = min(max(origin.x, screenFrame.minX + 8), screenFrame.maxX - panelSize.width - 8)
        origin.y = max(origin.y, screenFrame.minY + 8)

        panel.setFrameOrigin(origin)
    }

    private func center(panel: NSPanel) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = panel.frame.size
        let origin = NSPoint(
            x: screenFrame.midX - panelSize.width / 2,
            y: screenFrame.midY - panelSize.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private func screenRect(for view: NSView) -> NSRect? {
        guard let window = view.window else { return nil }

        let rectInWindow = view.convert(view.bounds, to: nil)
        return window.convertToScreen(rectInWindow)
    }
}
