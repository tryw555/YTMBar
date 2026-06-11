import Foundation

public struct NowPlayingSnapshot: Codable, Equatable {
    public static let empty = NowPlayingSnapshot(
        title: "YouTube Music",
        artist: "Open player to start",
        artworkURL: nil,
        artworkFileName: nil,
        isPlaying: false,
        updatedAt: Date()
    )

    public var title: String
    public var artist: String
    public var artworkURL: URL?
    public var artworkFileName: String?
    public var isPlaying: Bool
    public var updatedAt: Date

    public init(
        title: String,
        artist: String,
        artworkURL: URL?,
        artworkFileName: String?,
        isPlaying: Bool,
        updatedAt: Date
    ) {
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.artworkFileName = artworkFileName
        self.isPlaying = isPlaying
        self.updatedAt = updatedAt
    }
}

public enum SharedStorage {
    public static let appGroupIdentifier = "group.com.ozwin.ytmbar"
    public static let snapshotFileName = "now-playing.json"
    public static let artworkFileName = "now-playing-artwork.jpg"

    public static var containerURL: URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL
        }

        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        return baseURL.appendingPathComponent("YTMBar", isDirectory: true)
    }

    public static var snapshotURL: URL {
        containerURL.appendingPathComponent(snapshotFileName, isDirectory: false)
    }

    public static var artworkURL: URL {
        containerURL.appendingPathComponent(artworkFileName, isDirectory: false)
    }
}

public final class NowPlayingSnapshotStore {
    public static let shared = NowPlayingSnapshotStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.ozwin.ytmbar.now-playing-store", qos: .utility)

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func save(_ snapshot: NowPlayingSnapshot) {
        queue.async {
            do {
                try FileManager.default.createDirectory(
                    at: SharedStorage.containerURL,
                    withIntermediateDirectories: true
                )

                let data = try self.encoder.encode(snapshot)
                try data.write(to: SharedStorage.snapshotURL, options: .atomic)
            } catch {
                NSLog("YTMBar failed to save now-playing snapshot: \(error.localizedDescription)")
            }
        }
    }

    public func load() -> NowPlayingSnapshot {
        do {
            let data = try Data(contentsOf: SharedStorage.snapshotURL)
            return try decoder.decode(NowPlayingSnapshot.self, from: data)
        } catch {
            return .empty
        }
    }
}
