import Foundation

enum MenuBarStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    case circle
    case bars

    var id: String { rawValue }
}

struct AppSettings: Codable, Sendable {
    var refreshIntervalSeconds: Int = 300
    var language: AppLanguage = .english
    var menuBarStyle: MenuBarStyle = .circle

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "appSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
}

extension AppSettings {
    enum CodingKeys: String, CodingKey {
        case refreshIntervalSeconds
        case language
        case menuBarStyle
    }

    /// Tolerant decoding: missing keys fall back to defaults instead of throwing.
    /// This keeps existing users' saved settings intact when a new field is added
    /// (a synthesized decoder would throw on the missing key and reset everything).
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        refreshIntervalSeconds = try c.decodeIfPresent(Int.self, forKey: .refreshIntervalSeconds) ?? 300
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
        menuBarStyle = try c.decodeIfPresent(MenuBarStyle.self, forKey: .menuBarStyle) ?? .circle
    }
}
