import AppKit

final class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: PlayerDisplayMode.long.statusItemWidth)
    private let playerView = StatusBarPlayerView(frame: NSRect(x: 0, y: 0, width: PlayerDisplayMode.long.statusItemWidth, height: 24))
    private let hoverPreviewController = HoverPreviewController()
    private weak var commandTarget: PlaybackCommanding?

    private var playbackState: PlaybackState = .waiting
    private var currentArtwork: NSImage?
    private var displayMode: PlayerDisplayMode = AppSettings.shared.displayMode
    private var pendingPausedState: PlaybackState?
    private var pendingPausedWorkItem: DispatchWorkItem?

    init(commandTarget: PlaybackCommanding) {
        self.commandTarget = commandTarget
        configureStatusItem()
        updatePlaybackState(.waiting)
    }

    func updatePlaybackState(_ state: PlaybackState, bypassPauseStabilization: Bool = false) {
        if bypassPauseStabilization {
            pendingPausedWorkItem?.cancel()
            pendingPausedWorkItem = nil
            pendingPausedState = nil
            applyPlaybackState(state)
            return
        }

        let displayState = stabilizedState(for: state)
        applyPlaybackState(displayState)
    }

    private func applyPlaybackState(_ state: PlaybackState) {
        playbackState = state
        playerView.update(state: state, artwork: currentArtwork)

        ArtworkLoader.shared.loadArtwork(from: state.artworkURL) { [weak self] artwork in
            guard let self else { return }
            guard playbackState == state else { return }

            currentArtwork = artwork
            playerView.update(state: state, artwork: artwork)
        }
    }

    private func stabilizedState(for state: PlaybackState) -> PlaybackState {
        if state.isPlaying {
            pendingPausedWorkItem?.cancel()
            pendingPausedWorkItem = nil
            pendingPausedState = nil
            return state
        }

        guard playbackState.isPlaying, playbackState.isSameTrack(as: state) else {
            pendingPausedWorkItem?.cancel()
            pendingPausedWorkItem = nil
            pendingPausedState = nil
            return state
        }

        if pendingPausedState?.isSameTrack(as: state) != true {
            schedulePausedState(state)
        }

        var heldState = state
        heldState.isPlaying = true
        return heldState
    }

    private func schedulePausedState(_ state: PlaybackState) {
        pendingPausedWorkItem?.cancel()
        pendingPausedState = state

        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  pendingPausedState?.isSameTrack(as: state) == true,
                  playbackState.isSameTrack(as: state)
            else {
                return
            }

            pendingPausedState = nil
            pendingPausedWorkItem = nil
            applyPlaybackState(state)
        }

        pendingPausedWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        statusItem.length = displayMode.statusItemWidth
        button.frame.size.width = displayMode.statusItemWidth
        button.subviews.forEach { $0.removeFromSuperview() }
        button.addSubview(playerView)

        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: button.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        playerView.onPrevious = { [weak self] in
            self?.commandTarget?.playPrevious()
        }

        playerView.onTogglePlayPause = { [weak self] in
            self?.commandTarget?.togglePlayPause(source: .statusBar)
        }

        playerView.onNext = { [weak self] in
            self?.commandTarget?.playNext()
        }

        playerView.onOpenPanel = { [weak self] anchorView in
            self?.commandTarget?.togglePlayerPanel(from: anchorView)
        }

        playerView.onHoverBegan = { [weak self] anchorView in
            guard let self else { return }
            hoverPreviewController.show(from: anchorView, state: playbackState, artwork: currentArtwork)
        }

        playerView.onHoverEnded = { [weak self] in
            self?.hoverPreviewController.scheduleClose()
        }

        playerView.onModeSelected = { [weak self] mode in
            self?.applyDisplayMode(mode)
        }

        playerView.onQuit = {
            NSApp.terminate(nil)
        }

        playerView.apply(mode: displayMode)
    }

    private func applyDisplayMode(_ mode: PlayerDisplayMode) {
        displayMode = mode
        AppSettings.shared.displayMode = mode
        statusItem.length = mode.statusItemWidth
        statusItem.button?.frame.size.width = mode.statusItemWidth
        playerView.apply(mode: mode)
    }
}

private extension PlaybackState {
    func isSameTrack(as other: PlaybackState) -> Bool {
        title == other.title &&
            artist == other.artist
    }
}
