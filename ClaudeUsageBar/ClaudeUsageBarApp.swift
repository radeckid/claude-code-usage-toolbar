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
            } else {
                switch viewModel.settings.menuBarStyle {
                case .circle:
                    circleLabel
                case .bars:
                    // Same order as the popover bars: session → week → model
                    Image(nsImage: renderBars([
                        viewModel.sessionUtilization,
                        viewModel.weekUtilization,
                        viewModel.modelWeekUtilization
                    ].map { $0 ?? 0 }))
                }
            }
        }
    }

    @ViewBuilder private var circleLabel: some View {
        if progress >= 1.0 {
            Text("😢")
                .font(.system(size: 13))
        } else {
            Image(nsImage: renderCircle(progress: progress))
        }
        if let session = viewModel.sessionUtilization {
            Text("\(session.safePercentInt)%")
                .monospacedDigit()
        } else if let resetsAt = viewModel.sessionResetsAt {
            Text(formatResetTime(resetsAt)).fixedSize(horizontal: false, vertical: true)
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

    /// Mini vertical bar chart (monochrome template, matches the ring). Bars rise from the
    /// bottom; each value is a 0–100 percentage. Rendered left→right in the given order.
    private func renderBars(_ values: [Double]) -> NSImage {
        let barWidth: CGFloat = 3
        let spacing: CGFloat = 2
        let barHeight: CGFloat = 14
        let canvasHeight: CGFloat = 16
        let count = values.count
        let width = CGFloat(count) * barWidth + CGFloat(max(0, count - 1)) * spacing

        let image = NSImage(size: NSSize(width: max(width, 1), height: canvasHeight), flipped: false) { _ in
            let yBottom = (canvasHeight - barHeight) / 2

            for (index, value) in values.enumerated() {
                let x = CGFloat(index) * (barWidth + spacing)

                // Faint full-height track (low alpha = faint in template mode)
                let track = NSBezierPath(
                    roundedRect: NSRect(x: x, y: yBottom, width: barWidth, height: barHeight),
                    xRadius: 1, yRadius: 1
                )
                NSColor.black.withAlphaComponent(0.25).setFill()
                track.fill()

                // Solid value bar rising from the bottom (full alpha = bold in template mode)
                let clamped = min(max(value, 0), 100) / 100
                let filledHeight = barHeight * clamped
                if filledHeight > 0 {
                    let bar = NSBezierPath(
                        roundedRect: NSRect(x: x, y: yBottom, width: barWidth, height: filledHeight),
                        xRadius: 1, yRadius: 1
                    )
                    NSColor.black.setFill()
                    bar.fill()
                }
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
