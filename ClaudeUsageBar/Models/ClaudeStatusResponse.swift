import Foundation

struct ClaudeStatusResponse: Decodable {
    let page: StatusPage
    let status: OverallStatus
    let components: [StatusComponent]
    let incidents: [StatusIncident]
}

struct StatusPage: Decodable {
    let name: String
    let url: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case name, url
        case updatedAt = "updated_at"
    }
}

struct OverallStatus: Decodable {
    let indicator: String
    let description: String
}

struct StatusComponent: Decodable, Identifiable {
    let id: String
    let name: String
    let status: String
    let showcase: Bool

    var isOperational: Bool { status == "operational" }

    var statusColor: String {
        switch status {
        case "operational": return "green"
        case "degraded_performance": return "yellow"
        case "partial_outage": return "orange"
        case "major_outage": return "red"
        default: return "gray"
        }
    }
}

struct StatusIncident: Decodable, Identifiable {
    let id: String
    let name: String
    let status: String
    let impact: String
    let startedAt: Date
    let incidentUpdates: [IncidentUpdate]

    enum CodingKeys: String, CodingKey {
        case id, name, status, impact
        case startedAt = "started_at"
        case incidentUpdates = "incident_updates"
    }
}

struct IncidentUpdate: Decodable, Identifiable {
    let id: String
    let body: String
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, body, status
        case createdAt = "created_at"
    }
}
