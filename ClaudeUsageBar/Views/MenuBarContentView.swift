import SwiftUI

struct MenuBarContentView: View {
    @Bindable var viewModel: UsageDashboardViewModel
    var softwareUpdater: SoftwareUpdater

    private var lang: AppLanguage { viewModel.settings.language }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if viewModel.isLoading && viewModel.lastFetchDate == nil {
                ProgressView(L10n.loading(lang))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
            } else if !viewModel.hasData && viewModel.lastError != nil {
                noDataView
            } else if viewModel.hasData {
                if let warning = viewModel.lastError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(warning)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                RateLimitView(
                    sessionUtilization: viewModel.sessionUtilization,
                    sessionResetsAt: viewModel.sessionResetsAt,
                    weekUtilization: viewModel.weekUtilization,
                    weekResetsAt: viewModel.weekResetsAt,
                    sonnetUtilization: viewModel.sonnetUtilization,
                    sonnetResetsAt: viewModel.sonnetResetsAt,
                    extraUsageEnabled: viewModel.extraUsageEnabled,
                    extraUsageUsed: viewModel.extraUsageUsed,
                    extraUsageLimit: viewModel.extraUsageLimit,
                    extraUsageCurrency: viewModel.extraUsageCurrency,
                    lang: lang
                )
                .padding(16)
            } else {
                Spacer()
            }

            Divider()
            ClaudeStatusView(service: viewModel.statusService, lang: lang)
            Divider()
            footerSection

            if softwareUpdater.updateAvailable {
                Divider()
                updateBanner
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text(L10n.claudeUsage(lang))
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - No Data

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(L10n.noDataTitle(lang))
                .font(.headline)
            Text(viewModel.lastError ?? L10n.noDataMessage(lang))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(L10n.retry(lang)) {
                Task { await viewModel.manualRefresh() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 12) {
            if let lastFetch = viewModel.lastFetchDate {
                Text("\(L10n.updatedAgo(lang)) \(lastFetch, style: .relative) \(L10n.ago(lang))")
                    .environment(\.locale, Locale(identifier: lang.rawValue))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if viewModel.isLoading || viewModel.statusService.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Button(action: { Task { await viewModel.manualRefresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help(L10n.refresh(lang))

            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help(L10n.quit(lang))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Update Banner

    private var updateBanner: some View {
        Button {
            softwareUpdater.checkForUpdates()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                Text(L10n.updateAvailable(lang))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.blue, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}
