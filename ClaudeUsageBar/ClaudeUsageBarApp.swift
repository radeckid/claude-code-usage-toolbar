import SwiftUI

@main
struct ClaudeUsageBarApp: App {
    @State private var viewModel = UsageDashboardViewModel()
    @State private var softwareUpdater = SoftwareUpdater()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel, softwareUpdater: softwareUpdater)
                .frame(width: 320)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel, softwareUpdater: softwareUpdater)
        }
    }
}

struct MenuBarLabel: View {
    let viewModel: UsageDashboardViewModel

    private var progress: Double {
        (viewModel.sessionUtilization ?? 0) / 100.0
    }

    var body: some View {
        HStack(spacing: 3) {
            if let errorKind = viewModel.errorKind, !viewModel.hasData {
                switch errorKind {
                case .auth:
                    Image(systemName: "key.slash")
                case .other:
                    Image(systemName: "exclamationmark.triangle")
                }
            } else if progress >= 1.0 {
                Text("😢")
                    .font(.system(size: 13))
            } else {
                Image(nsImage: renderCircle(progress: progress))
            }
            if let session = viewModel.sessionUtilization {
                Text("\(Int(session))%")
                    .monospacedDigit()
            } else if let resetsAt = viewModel.sessionResetsAt {
                Text(formatResetTime(resetsAt)).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formatResetTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "MMM d"
        return formatter.string(from: date)
    }

    private func renderCircle(progress: Double) -> NSImage {
        let size: CGFloat = 16
        let lineWidth: CGFloat = 2.0
        let radius = (size - lineWidth) / 2

        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            let center = NSPoint(x: size / 2, y: size / 2)

            // Background ring (low alpha = faint in template mode)
            let bgPath = NSBezierPath()
            bgPath.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
            bgPath.lineWidth = lineWidth
            NSColor.black.withAlphaComponent(0.25).setStroke()
            bgPath.stroke()

            // Progress arc (full alpha = bold in template mode)
            if progress > 0 {
                let arcPath = NSBezierPath()
                let startAngle: CGFloat = 90
                let endAngle: CGFloat = 90 - (360 * min(progress, 1.0))
                arcPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                arcPath.lineWidth = lineWidth
                arcPath.lineCapStyle = .round
                NSColor.black.setStroke()
                arcPath.stroke()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
