import Foundation

enum AppLanguage: String, Codable, CaseIterable, Sendable, Identifiable {
    case english = "en"
    case polish = "pl"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .polish: return "Polski"
        }
    }
}

enum L10n {
    // MARK: - Menu Bar

    static func claudeUsage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Claude Usage"
        case .polish: return "Zużycie Claude"
        }
    }

    // MARK: - Rate Limits

    static func currentSession(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Current session"
        case .polish: return "Bieżąca sesja"
        }
    }

    static func currentWeek(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Current week"
        case .polish: return "Bieżący tydzień"
        }
    }

    static func currentWeekSonnet(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Current week (Sonnet)"
        case .polish: return "Bieżący tydzień (Sonnet)"
        }
    }

    static func extraUsage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Extra usage"
        case .polish: return "Dodatkowe zużycie"
        }
    }

    static func monthly(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Monthly"
        case .polish: return "Miesięcznie"
        }
    }

    static func used(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "used"
        case .polish: return "zużyte"
        }
    }

    static func resetsAt(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Resets"
        case .polish: return "Reset:"
        }
    }

    // MARK: - No Data

    static func noDataTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "No Data Found"
        case .polish: return "Brak danych"
        }
    }

    static func noDataMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Could not fetch rate limits.\nCheck Claude Code credentials."
        case .polish: return "Nie można pobrać limitów.\nSprawdź dane logowania Claude Code."
        }
    }

    // MARK: - Footer

    static func updatedAgo(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Updated"
        case .polish: return "Zaktualizowano"
        }
    }

    static func ago(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "ago"
        case .polish: return "temu"
        }
    }

    static func refresh(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Refresh"
        case .polish: return "Odśwież"
        }
    }

    static func quit(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Quit"
        case .polish: return "Zamknij"
        }
    }

    static func loading(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Loading..."
        case .polish: return "Ładowanie..."
        }
    }

    // MARK: - Error

    static func retry(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Retry"
        case .polish: return "Ponów"
        }
    }

    static func sessionExpiredMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Session expired.\nRun `claude` in terminal to re-authenticate."
        case .polish: return "Sesja wygasła.\nUruchom `claude` w terminalu, aby ponownie się uwierzytelnić."
        }
    }

    static func keychainNotFound(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Claude Code credentials not found.\nRun `claude` in terminal first."
        case .polish: return "Nie znaleziono danych Claude Code.\nNajpierw uruchom `claude` w terminalu."
        }
    }

    static func rateLimitedMessage(_ lang: AppLanguage, retryAfter: TimeInterval? = nil) -> String {
        let base: String
        switch lang {
        case .english: base = "Too many requests (429)."
        case .polish: base = "Zbyt wiele zapytań (429)."
        }

        if let retryAfter, retryAfter > 0 {
            let minutes = Int(ceil(retryAfter / 60))
            let timeStr: String
            switch lang {
            case .english:
                timeStr = minutes == 1 ? "Retry in ~1 minute." : "Retry in ~\(minutes) minutes."
            case .polish:
                if minutes == 1 {
                    timeStr = "Ponów za ~1 minutę."
                } else if minutes < 5 {
                    timeStr = "Ponów za ~\(minutes) minuty."
                } else {
                    timeStr = "Ponów za ~\(minutes) minut."
                }
            }
            return "\(base)\n\(timeStr)"
        }

        switch lang {
        case .english: return "\(base)\nTry again later."
        case .polish: return "\(base)\nSpróbuj ponownie później."
        }
    }

    // MARK: - Settings

    static func settingsTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Settings"
        case .polish: return "Ustawienia"
        }
    }

    static func general(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "General"
        case .polish: return "Ogólne"
        }
    }

    static func about(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "About"
        case .polish: return "O aplikacji"
        }
    }

    static func autoRefreshEvery(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Auto-refresh every"
        case .polish: return "Odświeżaj co"
        }
    }

    static func launchAtLogin(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Launch at Login"
        case .polish: return "Uruchom po zalogowaniu"
        }
    }

    static func language(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Language"
        case .polish: return "Język"
        }
    }

    static func display(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Display"
        case .polish: return "Wyświetlanie"
        }
    }

    static func system(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "System"
        case .polish: return "System"
        }
    }

    static func refreshSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Refresh"
        case .polish: return "Odświeżanie"
        }
    }

    static func minute1(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "1 minute"
        case .polish: return "1 minuta"
        }
    }

    static func minutes2(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "2 minutes"
        case .polish: return "2 minuty"
        }
    }

    static func minutes5(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "5 minutes"
        case .polish: return "5 minut"
        }
    }

    static func minutes15(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "15 minutes"
        case .polish: return "15 minut"
        }
    }

    static func minutes30(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "30 minutes"
        case .polish: return "30 minut"
        }
    }

    static func hour1(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "1 hour"
        case .polish: return "1 godzina"
        }
    }

    static func aboutDescription(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Monitor your Claude Code usage\ndirectly from the menu bar."
        case .polish: return "Monitoruj zużycie Claude Code\nbezpośrednio z paska menu."
        }
    }

    static func checkForUpdates(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Check for Updates..."
        case .polish: return "Sprawdź aktualizacje..."
        }
    }

    static func updateAvailable(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "New version available"
        case .polish: return "Dostępna nowa wersja"
        }
    }

    // MARK: - Claude Status

    static func claudeStatus(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Claude Status"
        case .polish: return "Status Claude"
        }
    }

    static func openStatusPage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Open status.claude.com"
        case .polish: return "Otwórz status.claude.com"
        }
    }

    static func statusFetchError(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Could not load status."
        case .polish: return "Nie można załadować statusu."
        }
    }

    static func statusOperational(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Operational"
        case .polish: return "Działa"
        }
    }

    static func statusDegraded(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Degraded"
        case .polish: return "Obniżona wydajność"
        }
    }

    static func statusPartialOutage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Partial Outage"
        case .polish: return "Częściowa awaria"
        }
    }

    static func statusMajorOutage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Major Outage"
        case .polish: return "Poważna awaria"
        }
    }
}
