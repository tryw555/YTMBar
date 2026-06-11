import Foundation

final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private let displayModeKey = "ytmbar.displayMode"

    private init() {}

    var displayMode: PlayerDisplayMode {
        get {
            let rawValue = defaults.integer(forKey: displayModeKey)
            return PlayerDisplayMode(rawValue: rawValue) ?? .long
        }
        set {
            defaults.set(newValue.rawValue, forKey: displayModeKey)
        }
    }
}
