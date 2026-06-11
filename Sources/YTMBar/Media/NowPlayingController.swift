import AppKit
import MediaPlayer

final class NowPlayingController {
    private weak var commandTarget: PlaybackCommanding?
    private var currentArtwork: MPMediaItemArtwork?
    private var isPlaying = false

    init(commandTarget: PlaybackCommanding) {
        self.commandTarget = commandTarget
        configureRemoteCommands()
    }

    func update(state: PlaybackState, artwork: NSImage?) {
        isPlaying = state.isPlaying

        if let artwork {
            currentArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        } else {
            currentArtwork = nil
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: state.title,
            MPMediaItemPropertyArtist: state.artist,
            MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0
        ]

        if let currentArtwork {
            info[MPMediaItemPropertyArtwork] = currentArtwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = state.isPlaying ? .playing : .paused
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            DiagnosticsLogger.shared.log("System command: previous")
            self?.commandTarget?.playPrevious()
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            DiagnosticsLogger.shared.log("System command: toggle")
            self?.commandTarget?.togglePlayPause(source: .system)
            return .success
        }

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            DiagnosticsLogger.shared.log("System command: play current=\(isPlaying)")
            if !isPlaying {
                commandTarget?.setPlayback(playing: true, source: .system)
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            DiagnosticsLogger.shared.log("System command: pause current=\(isPlaying)")
            if isPlaying {
                commandTarget?.setPlayback(playing: false, source: .system)
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            DiagnosticsLogger.shared.log("System command: next")
            self?.commandTarget?.playNext()
            return .success
        }
    }
}
