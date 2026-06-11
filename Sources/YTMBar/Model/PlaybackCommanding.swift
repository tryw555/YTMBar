import AppKit

enum PlaybackCommandSource: String {
    case statusBar
    case system
    case url
}

protocol PlaybackCommanding: AnyObject {
    func playPrevious()
    func togglePlayPause(source: PlaybackCommandSource)
    func setPlayback(playing shouldPlay: Bool, source: PlaybackCommandSource)
    func playNext()
    func togglePlayerPanel(from anchorView: NSView)
}
