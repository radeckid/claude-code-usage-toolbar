import Foundation
@preconcurrency import Sparkle

@Observable
@MainActor
final class SoftwareUpdater {

    var canCheckForUpdates = false
    var updateAvailable = false

    private let updater: SPUUpdater
    private let delegate: UpdaterDelegate
    private var observation: NSKeyValueObservation?

    init() {
        let delegate = UpdaterDelegate()
        self.delegate = delegate

        let userDriver = SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil)
        updater = SPUUpdater(
            hostBundle: Bundle.main,
            applicationBundle: Bundle.main,
            userDriver: userDriver,
            delegate: delegate
        )

        delegate.onUpdateFound = { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateAvailable = true
            }
        }

        observation = updater.observe(
            \.canCheckForUpdates,
            options: [.initial, .new]
        ) { [weak self] _, change in
            let newValue = change.newValue ?? false
            Task { @MainActor [weak self] in
                self?.canCheckForUpdates = newValue
            }
        }

        do {
            try updater.start()
        } catch {
            print("Sparkle updater failed to start: \(error)")
        }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}

// MARK: - Delegate

private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate, @unchecked Sendable {
    var onUpdateFound: (() -> Void)?

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        onUpdateFound?()
    }
}
