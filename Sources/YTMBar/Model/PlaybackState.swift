import CoreGraphics
import Foundation

struct PlaybackState: Equatable {
    var title: String
    var artist: String
    var artworkURL: URL?
    var isPlaying: Bool

    static let waiting = PlaybackState(
        title: "YouTube Music",
        artist: "Open player to start",
        artworkURL: nil,
        isPlaying: false
    )
}

enum PlayerDisplayMode: Int, CaseIterable {
    case long
    case medium
    case compact

    var statusItemWidth: CGFloat {
        switch self {
        case .long:
            return 352
        case .medium:
            return 248
        case .compact:
            return 122
        }
    }

    var menuTitle: String {
        switch self {
        case .long:
            return "긴 버전"
        case .medium:
            return "보통 버전"
        case .compact:
            return "짧은 버전"
        }
    }
}
