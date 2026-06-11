import AppKit
import YTMBarShared

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: PlayerPanelController?
    private var statusBarController: StatusBarController?
    private var nowPlayingController: NowPlayingController?
    private var isDuplicateInstance = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerURLHandler()
        registerDistributedCommandHandler()

        if prepareDuplicateInstanceForForwarding() {
            DiagnosticsLogger.shared.log("Duplicate instance detected; waiting briefly to forward URL command.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NSApp.terminate(nil)
            }
            return
        }

        DiagnosticsLogger.shared.log("Application launched: \(Bundle.main.bundlePath)")

        let panelController = PlayerPanelController()
        let statusBarController = StatusBarController(commandTarget: panelController)
        let nowPlayingController = NowPlayingController(commandTarget: panelController)

        panelController.onPlaybackStateChange = { [weak statusBarController, weak nowPlayingController] state, artwork, bypassPauseStabilization in
            statusBarController?.updatePlaybackState(state, bypassPauseStabilization: bypassPauseStabilization)
            nowPlayingController?.update(state: state, artwork: artwork)

            let artworkFileName = ArtworkFileWriter.saveArtwork(artwork)
            let snapshot = NowPlayingSnapshot(
                title: state.title,
                artist: state.artist,
                artworkURL: state.artworkURL,
                artworkFileName: artworkFileName,
                isPlaying: state.isPlaying,
                updatedAt: Date()
            )
            NowPlayingSnapshotStore.shared.save(snapshot)
        }

        self.panelController = panelController
        self.statusBarController = statusBarController
        self.nowPlayingController = nowPlayingController
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func registerURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    private func registerDistributedCommandHandler() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleDistributedCommand(_:)),
            name: .ytmbarCommand,
            object: nil
        )
    }

    private func prepareDuplicateInstanceForForwarding() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return false
        }

        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let otherInstances = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .filter { $0.processIdentifier != currentProcessIdentifier }

        guard let existingInstance = otherInstances.first else {
            return false
        }

        isDuplicateInstance = true
        existingInstance.activate(options: [.activateAllWindows])
        return true
    }

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString),
              url.scheme == "ytmbar"
        else {
            return
        }

        let command = url.host ?? "open"

        if isDuplicateInstance {
            DistributedNotificationCenter.default().post(name: .ytmbarCommand, object: command)
            DiagnosticsLogger.shared.log("Forwarded URL command to existing instance: \(command)")
            NSApp.terminate(nil)
            return
        }

        perform(command: command)
    }

    @objc private func handleDistributedCommand(_ notification: Notification) {
        guard !isDuplicateInstance,
              let command = notification.object as? String
        else {
            return
        }

        DiagnosticsLogger.shared.log("Received forwarded command: \(command)")
        perform(command: command)
    }

    private func perform(command: String) {
        DiagnosticsLogger.shared.log("URL command: \(command)")

        switch command {
        case "open":
            panelController?.showPlayerPanelCentered()
        case "previous":
            panelController?.playPrevious()
        case "playpause":
            panelController?.togglePlayPause(source: .url)
        case "next":
            panelController?.playNext()
        default:
            panelController?.showPlayerPanelCentered()
        }
    }
}

private extension Notification.Name {
    static let ytmbarCommand = Notification.Name("com.ozwin.ytmbar.command")
}
