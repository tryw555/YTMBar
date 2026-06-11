import AppKit
import Foundation
import YTMBarShared

enum ArtworkFileWriter {
    static func saveArtwork(_ image: NSImage?) -> String? {
        guard let image,
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.82])
        else {
            try? FileManager.default.removeItem(at: SharedStorage.artworkURL)
            return nil
        }

        do {
            try FileManager.default.createDirectory(
                at: SharedStorage.containerURL,
                withIntermediateDirectories: true
            )
            try jpegData.write(to: SharedStorage.artworkURL, options: .atomic)
            return SharedStorage.artworkFileName
        } catch {
            NSLog("YTMBar failed to save artwork: \(error.localizedDescription)")
            return nil
        }
    }
}
