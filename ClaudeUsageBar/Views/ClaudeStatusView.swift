import SwiftUI

struct ClaudeStatusView: View {
    let service: ClaudeStatusService
    let lang: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusHeader

            if service.isLoading && service.lastFetchDate == nil {
                Divider()
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(16)
            } else if let status = service.status, hasContent(status) {
                Divider()
                statusContent(status)
            } else if service.status == nil && service.lastFetchDate != nil {
                Divider()
                Text(L10n.statusFetchError(lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(16)
            }
        }
    }

    // MARK: - Header

    private var statusHeader: some View {
        HStack {
            Circle()
                .fill(overallIndicatorColor)
                .frame(width: 8, height: 8)
            Text(L10n.claudeStatus(lang))
                .font(.headline)
            Spacer()
            if service.isLoading {
                ProgressView()
                    .controlSize(.mini)
            }
            Link(destination: URL(string: "https://status.claude.com")!) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)
            .help(L10n.openStatusPage(lang))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var overallIndicatorColor: Color {
        guard let indicator = service.status?.status.indicator else {
            return .gray
        }
        switch indicator {
        case "none": return .green
        case "minor": return .yellow
        case "major": return .orange
        case "critical": return .red
        default: return .gray
        }
    }

    // MARK: - Content

    private func hasContent(_ status: ClaudeStatusResponse) -> Bool {
        status.status.indicator != "none"
            || !status.incidents.isEmpty
            || status.components.contains { $0.showcase && !$0.isOperational }
    }

    @ViewBuilder
    private func statusContent(_ status: ClaudeStatusResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Overall status — only show when there are problems
            if status.status.indicator != "none" {
                Text(status.status.description)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            // Active incidents
            if !status.incidents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(status.incidents) { incident in
                        incidentRow(incident)
                    }
                }
            }

            // Components (only non-operational ones)
            let degraded = status.components.filter { $0.showcase && !$0.isOperational }
            if !degraded.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(degraded) { component in
                        componentRow(component)
                    }
                }
            }
        }
        .padding(16)
    }

    private func incidentRow(_ incident: StatusIncident) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(impactColor(incident.impact))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(incident.name)
                    .font(.caption.bold())
                    .lineLimit(2)
                if let latestUpdate = incident.incidentUpdates.first {
                    Text(latestUpdate.body)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private func componentRow(_ component: StatusComponent) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(componentColor(component.statusColor))
                .frame(width: 6, height: 6)
            Text(component.name)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            Text(componentStatusLabel(component.status))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func impactColor(_ impact: String) -> Color {
        switch impact {
        case "critical": return .red
        case "major": return .orange
        case "minor": return .yellow
        default: return .secondary
        }
    }

    private func componentColor(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }

    private func componentStatusLabel(_ status: String) -> String {
        switch status {
        case "operational": return L10n.statusOperational(lang)
        case "degraded_performance": return L10n.statusDegraded(lang)
        case "partial_outage": return L10n.statusPartialOutage(lang)
        case "major_outage": return L10n.statusMajorOutage(lang)
        default: return status
        }
    }
}
