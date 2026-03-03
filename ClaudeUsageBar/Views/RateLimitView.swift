import SwiftUI

struct RateLimitView: View {
    let sessionUtilization: Double?
    let sessionResetsAt: Date?
    let weekUtilization: Double?
    let weekResetsAt: Date?
    let sonnetUtilization: Double?
    let sonnetResetsAt: Date?
    let extraUsageEnabled: Bool
    let extraUsageUsed: Double?
    let extraUsageLimit: Double?
    let extraUsageCurrency: String?
    let lang: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            if let session = sessionUtilization {
                rateLimitBar(
                    label: L10n.currentSession(lang),
                    utilization: session,
                    resetsAt: sessionResetsAt
                )
            }

            if let week = weekUtilization {
                rateLimitBar(
                    label: L10n.currentWeek(lang),
                    utilization: week,
                    resetsAt: weekResetsAt
                )
            }

            if let sonnet = sonnetUtilization {
                rateLimitBar(
                    label: L10n.currentWeekSonnet(lang),
                    utilization: sonnet,
                    resetsAt: sonnetResetsAt
                )
            }

            if extraUsageEnabled, let used = extraUsageUsed, let limit = extraUsageLimit {
                extraUsageBar(used: used, limit: limit, currency: extraUsageCurrency ?? "USD")
            }
        }
    }

    private func rateLimitBar(label: String, utilization: Double, resetsAt: Date?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.bold())
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: utilization))
                        .frame(
                            width: max(0, min(geometry.size.width, geometry.size.width * utilization / 100)),
                            height: 10
                        )
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(Int(utilization))% \(L10n.used(lang))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(textColor(for: utilization))

                Spacer()

                if let resetsAt {
                    Text("\(L10n.resetsAt(lang)) \(formatResetTime(resetsAt, lang: lang))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func extraUsageBar(used: Double, limit: Double, currency: String) -> some View {
        let utilization = limit > 0 ? (used / limit) * 100 : 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.extraUsage(lang))
                    .font(.subheadline.bold())
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: utilization))
                        .frame(
                            width: max(0, min(geometry.size.width, geometry.size.width * utilization / 100)),
                            height: 10
                        )
                }
            }
            .frame(height: 10)

            HStack {
                Text(formatCurrency(used, currency: currency) + " / " + formatCurrency(limit, currency: currency))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(textColor(for: utilization))

                Spacer()

                Text(L10n.monthly(lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatCurrency(_ value: Double, currency: String) -> String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        default: symbol = currency + " "
        }
        return String(format: "%@%.2f", symbol, value)
    }

    private func barColor(for utilization: Double) -> Color {
        if utilization >= 90 { return .red }
        if utilization >= 70 { return .orange }
        if utilization >= 50 { return .yellow }
        return .green
    }

    private func textColor(for utilization: Double) -> Color {
        if utilization >= 90 { return .red }
        if utilization >= 70 { return .orange }
        return .secondary
    }

    private func formatResetTime(_ date: Date, lang: AppLanguage) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: lang.rawValue)
            switch lang {
            case .english:
                formatter.dateFormat = "h:mma"
                formatter.amSymbol = "am"
                formatter.pmSymbol = "pm"
            case .polish:
                formatter.dateFormat = "HH:mm"
            }
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: lang.rawValue)
            switch lang {
            case .english: formatter.dateFormat = "MMM d"
            case .polish: formatter.dateFormat = "d MMM"
            }
            return formatter.string(from: date)
        }
    }
}
