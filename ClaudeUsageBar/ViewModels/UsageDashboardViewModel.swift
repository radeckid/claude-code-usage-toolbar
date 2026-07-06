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
    var modelWeekUtilization: Double?
    var modelWeekResetsAt: Date?
    var modelWeekName: String?

    // Extra usage (cost tracking)
    var extraUsageEnabled = false
    var extraUsageUsed: Double?
    var extraUsageLimit: Double?
    var extraUsageCurrency: String?
    var extraUsagePercent: Double?

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
                lastError = L10n.rateLimitedMessage(settings.language, retryAfter: retryAfter)
                errorKind = .other
            case .rateLimitedWithCache(let cached, let retryAfter):
                applyCachedResponse(cached)
                lastFetchDate = Date()
                lastError = L10n.rateLimitedMessage(settings.language, retryAfter: retryAfter)
                errorKind = .other
            default:
                lastError = error.localizedDescription
                errorKind = .other
            }
        } catch is CancellationError {
            // Task was cancelled (e.g. timer restart) — ignore silently
        } catch {
            if (error as? URLError)?.code == .cancelled { return }
            lastError = error.localizedDescription
            errorKind = .other
        }

        isLoading = false
    }

    func manualRefresh() async {
        await refresh()
        startAutoRefresh(immediate: false)
    }

    func restartAutoRefresh() {
        startAutoRefresh(immediate: false)
    }

    // MARK: - Auto Refresh

    func startAutoRefresh(immediate: Bool = true) {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            if immediate {
                await self?.refresh()
            }
            while !Task.isCancelled {
                let interval = self?.settings.refreshIntervalSeconds ?? 300
                try? await Task.sleep(for: .seconds(Double(interval)))
                guard !Task.isCancelled else { break }
                await self?.refresh()
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

        // Model-scoped weekly limit: new source is `limits.weekly_scoped`; fall back to
        // the legacy per-model windows (both null in the current API) for old cached data.
        if let scoped = response.limits?.first(where: { $0.scope?.model?.displayName != nil }),
           let util = scoped.percent {
            modelWeekUtilization = util
            modelWeekResetsAt = scoped.resetsAt.flatMap { Self.parseISO8601($0) }
            modelWeekName = scoped.scope?.model?.displayName
        } else if let modelWindow = response.sevenDaySonnet ?? response.sevenDayOpus,
                  let util = modelWindow.utilization {
            modelWeekUtilization = util
            modelWeekResetsAt = modelWindow.resetsAt.flatMap { Self.parseISO8601($0) }
            modelWeekName = response.sevenDaySonnet != nil ? "Sonnet" : "Opus"
        } else {
            modelWeekUtilization = nil
            modelWeekResetsAt = nil
            modelWeekName = nil
        }

        // Cost bar: prefer the richer `spend` object (honors exponent + API percent),
        // fall back to the legacy `extra_usage` fields.
        if let spend = response.spend, spend.enabled == true,
           let used = spend.used?.amount, let limit = spend.limit?.amount {
            extraUsageEnabled = true
            extraUsageUsed = used
            extraUsageLimit = limit
            extraUsageCurrency = spend.used?.currency ?? spend.limit?.currency ?? "USD"
            extraUsagePercent = spend.percent
        } else if let extra = response.extraUsage, extra.isEnabled == true {
            let divisor = pow(10.0, Double(extra.decimalPlaces ?? 2))
            extraUsageEnabled = true
            extraUsageUsed = extra.usedCredits.map { $0 / divisor }
            extraUsageLimit = extra.monthlyLimit.map { $0 / divisor }
            extraUsageCurrency = extra.currency ?? "USD"
            extraUsagePercent = extra.utilization
        } else {
            extraUsageEnabled = false
            extraUsageUsed = nil
            extraUsageLimit = nil
            extraUsageCurrency = nil
            extraUsagePercent = nil
        }

        hasData = true
    }

    private func applyCachedResponse(_ response: OAuthUsageResponse) {
        applyResponse(response)
    }

    private static func parseISO8601(_ string: String) -> Date? {
        iso8601Formatter.date(from: string)
            ?? iso8601FormatterNoFraction.date(from: string)
    }
}
