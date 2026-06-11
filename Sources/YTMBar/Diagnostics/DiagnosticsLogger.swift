import Foundation
import YTMBarShared

final class DiagnosticsLogger {
    static let shared = DiagnosticsLogger()

    private let queue = DispatchQueue(label: "com.ozwin.ytmbar.diagnostics", qos: .utility)
    private let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {}

    var logURL: URL {
        SharedStorage.containerURL.appendingPathComponent("diagnostics.log", isDirectory: false)
    }

    func log(_ message: String) {
        queue.async {
            do {
                try FileManager.default.createDirectory(
                    at: SharedStorage.containerURL,
                    withIntermediateDirectories: true
                )

                let timestamp = self.formatter.string(from: Date())
                let line = "[\(timestamp)] \(message)\n"
                let data = Data(line.utf8)

                if FileManager.default.fileExists(atPath: self.logURL.path) {
                    let handle = try FileHandle(forWritingTo: self.logURL)
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                } else {
                    try data.write(to: self.logURL, options: .atomic)
                }
            } catch {
                NSLog("YTMBar diagnostics logging failed: \(error.localizedDescription)")
            }
        }
    }
}
