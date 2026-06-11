import AppKit
import Foundation

final class ArtworkLoader {
    static let shared = ArtworkLoader()

    private var cache: [URL: NSImage] = [:]

    private init() {}

    func loadArtwork(from url: URL?, completion: @escaping (NSImage?) -> Void) {
        guard let url else {
            completion(nil)
            return
        }

        if let cachedImage = cache[url] {
            completion(cachedImage)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            let image = data.flatMap(NSImage.init(data:))

            DispatchQueue.main.async {
                if let image {
                    self?.cache[url] = image
                }

                completion(image)
            }
        }.resume()
    }
}
