import Foundation

struct OAuthUsageResponse: Codable, Sendable {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let sevenDayOAuthApps: UsageWindow?
    let sevenDayOpus: UsageWindow?
    let sevenDaySonnet: UsageWindow?
    let iguanaNecktie: UsageWindow?
    let extraUsage: ExtraUsage?
    let limits: [UsageLimit]?
    let spend: Spend?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOAuthApps = "seven_day_oauth_apps"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
        case iguanaNecktie = "iguana_necktie"
        case extraUsage = "extra_usage"
        case limits
        case spend
    }
}

struct UsageWindow: Codable, Sendable {
    let utilization: Double?
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct ExtraUsage: Codable, Sendable {
    let isEnabled: Bool?
    let monthlyLimit: Double?
    let usedCredits: Double?
    let utilization: Double?
    let currency: String?
    let decimalPlaces: Int?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
        case currency
        case decimalPlaces = "decimal_places"
    }
}

/// One entry of the `limits` array (session / weekly_all / weekly_scoped).
struct UsageLimit: Codable, Sendable {
    let kind: String?
    let group: String?
    let percent: Double?
    let severity: String?
    let resetsAt: String?
    let scope: LimitScope?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case kind
        case group
        case percent
        case severity
        case resetsAt = "resets_at"
        case scope
        case isActive = "is_active"
    }
}

struct LimitScope: Codable, Sendable {
    let model: LimitModel?
}

struct LimitModel: Codable, Sendable {
    let id: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

/// Richer spend/credits object (successor to `extra_usage`).
struct Spend: Codable, Sendable {
    let used: Money?
    let limit: Money?
    let percent: Double?
    let severity: String?
    let enabled: Bool?
    let disabledReason: String?

    enum CodingKeys: String, CodingKey {
        case used
        case limit
        case percent
        case severity
        case enabled
        case disabledReason = "disabled_reason"
    }
}

struct Money: Codable, Sendable {
    let amountMinor: Double?
    let currency: String?
    let exponent: Int?

    enum CodingKeys: String, CodingKey {
        case amountMinor = "amount_minor"
        case currency
        case exponent
    }

    /// Minor units → currency units (e.g. 1105 with exponent 2 → 11.05).
    var amount: Double? {
        guard let amountMinor, let exponent else { return nil }
        return amountMinor / pow(10.0, Double(exponent))
    }
}
