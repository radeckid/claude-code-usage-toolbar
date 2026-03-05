import Foundation
import SwiftUI

enum ErrorKind {
    case auth
    case other
}

@Observable
@MainActor
final class UsageDashboardViewModel {

    // MARK: - State

    var isLoading = false
    var lastFetchDate: Date?

    // Rate limits (from OAuth API)
    var sessionUtilization: Double?
    var sessionResetsAt: Date?
    var weekUtilization: Double?
    var weekResetsAt: Date?
    var sonnetUtilization: Double?
    var sonnetResetsAt: Date?

    // Extra usage (cost tracking)
    var extraUsageEnabled = false
    var extraUsageUsed: Double?
    var extraUsageLimit: Double?
    var extraUsageCurrency: String?

    var hasData = false
    var lastError: String?
    var errorKind: ErrorKind?

    var settings: AppSettings {
        didSet {
            settings.save()
        }
    }

    // MARK: - Private

    @ObservationIgnored private let oauthService = OAuthUsageService()
    let statusService = ClaudeStatusService()
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var retryAfterOverride: TimeInterval?

    nonisolated(unsafe) private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Init

    init() {
        self.settings = AppSettings.load()
        startAutoRefresh()
    }

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Public

    func refresh() async {
        isLoading = true
        lastError = nil
        errorKind = nil

        do {
            async let statusFetch: Void = statusService.fetch()
            let response = try await oauthService.fetchUsage()
            applyResponse(response)
            lastFetchDate = Date()
            retryAfterOverride = nil
            _ = await statusFetch
        } catch let error as OAuthUsageError {
            switch error {
            case .sessionExpired:
                lastError = L10n.sessionExpiredMessage(settings.language)
                errorKind = .auth
            case .keychainError:
                lastError = L10n.keychainNotFound(settings.language)
                errorKind = .auth
            case .rateLimited(let retryAfter):
                retryAfterOverride = retryAfter
                lastError = L10n.rateLimitedMessage(settings.language, retryAfter: retryAfter)
                errorKind = .other
            case .rateLimitedWithCache(let cached, let retryAfter):
                applyCachedResponse(cached)
                retryAfterOverride = retryAfter
                lastError = L10n.rateLimitedMessage(settings.language, retryAfter: retryAfter)
                errorKind = .other
            default:
                lastError = error.localizedDescription
                errorKind = .other
            }
        } catch {
            lastError = error.localizedDescription
            errorKind = .other
        }

        isLoading = false
    }

    func manualRefresh() async {
        retryAfterOverride = nil
        await refresh()
        restartAutoRefresh()
    }

    func restartAutoRefresh() {
        startAutoRefresh()
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                let retryAfter = self?.retryAfterOverride
                let normalInterval = self?.settings.refreshIntervalSeconds ?? 300
                let interval = max(Double(normalInterval), retryAfter ?? 0)
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    // MARK: - Private

    private func applyResponse(_ response: OAuthUsageResponse) {
        if let fiveHour = response.fiveHour, let util = fiveHour.utilization {
            sessionUtilization = util
            sessionResetsAt = fiveHour.resetsAt.flatMap { Self.parseISO8601($0) }
        }

        if let sevenDay = response.sevenDay, let util = sevenDay.utilization {
            weekUtilization = util
            weekResetsAt = sevenDay.resetsAt.flatMap { Self.parseISO8601($0) }
        }

        let modelWindow = response.sevenDaySonnet ?? response.sevenDayOpus
        if let modelWindow, let util = modelWindow.utilization {
            sonnetUtilization = util
            sonnetResetsAt = modelWindow.resetsAt.flatMap { Self.parseISO8601($0) }
        } else {
            sonnetUtilization = nil
            sonnetResetsAt = nil
        }

        if let extra = response.extraUsage, extra.isEnabled == true {
            extraUsageEnabled = true
            extraUsageUsed = extra.usedCredits.map { $0 / 100.0 }
            extraUsageLimit = extra.monthlyLimit.map { $0 / 100.0 }
            extraUsageCurrency = extra.currency ?? "USD"
        } else {
            extraUsageEnabled = false
            extraUsageUsed = nil
            extraUsageLimit = nil
            extraUsageCurrency = nil
        }

        hasData = true
    }

    private func applyCachedResponse(_ response: OAuthUsageResponse) {
        applyResponse(response)
        // Don't update lastFetchDate — it's cached data, not fresh
    }

    private static func parseISO8601(_ string: String) -> Date? {
        iso8601Formatter.date(from: string)
            ?? iso8601FormatterNoFraction.date(from: string)
    }
}
