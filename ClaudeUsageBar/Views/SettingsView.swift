import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: UsageDashboardViewModel
    var softwareUpdater: SoftwareUpdater

    private var lang: AppLanguage { viewModel.settings.language }

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label(L10n.general(lang), systemImage: "gear") }
            aboutTab
                .tabItem { Label(L10n.about(lang), systemImage: "info.circle") }
        }
        .frame(width: 420, height: 300)
        .background(WindowTitleSetter(title: L10n.settingsTitle(lang)))
        .onAppear {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section(L10n.refreshSection(lang)) {
                Picker(L10n.autoRefreshEvery(lang), selection: $viewModel.settings.refreshIntervalSeconds) {
                    Text(L10n.minute1(lang)).tag(60)
                    Text(L10n.minutes2(lang)).tag(120)
                    Text(L10n.minutes5(lang)).tag(300)
                    Text(L10n.minutes15(lang)).tag(900)
                    Text(L10n.minutes30(lang)).tag(1800)
                    Text(L10n.hour1(lang)).tag(3600)
                }
                .onChange(of: viewModel.settings.refreshIntervalSeconds) {
                    viewModel.restartAutoRefresh()
                }
            }

            Section(L10n.display(lang)) {
                Picker(L10n.language(lang), selection: $viewModel.settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section(L10n.system(lang)) {
                Toggle(L10n.launchAtLogin(lang), isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            // Silently fail - not critical
                        }
                    }
                ))
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)
            Text("Claude Usage Bar")
                .font(.title2.bold())
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("by Damian \"Damrad\" Radecki")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(L10n.aboutDescription(lang))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button(L10n.checkForUpdates(lang)) {
                softwareUpdater.checkForUpdates()
            }
            .disabled(!softwareUpdater.canCheckForUpdates)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Window Title Override

/// Overrides the window title that macOS TabView sets automatically.
/// Sets the title with a small delay so it fires after TabView's own title update.
private struct WindowTitleSetter: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.setFrameSize(.zero)
        setTitle(on: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        setTitle(on: nsView)
    }

    private func setTitle(on view: NSView) {
        let desired = title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            view.window?.title = desired
        }
    }
}
