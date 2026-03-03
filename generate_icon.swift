#!/usr/bin/swift

import AppKit
import Foundation

func generateIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let s = CGFloat(size)

    // Background - rounded rectangle with purple gradient
    let cornerRadius = s * 0.22
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    let gradient = NSGradient(colors: [
        NSColor(red: 0.45, green: 0.20, blue: 0.85, alpha: 1.0),
        NSColor(red: 0.60, green: 0.30, blue: 0.95, alpha: 1.0),
    ])!
    gradient.draw(in: bgPath, angle: -45)

    // Draw bar chart icon
    let barColor = NSColor.white.withAlphaComponent(0.95)
    barColor.setFill()

    let margin = s * 0.22
    let barSpacing = s * 0.04
    let barAreaWidth = s - margin * 2
    let barAreaHeight = s - margin * 2
    let barWidth = (barAreaWidth - barSpacing * 2) / 3

    // Bar heights (relative)
    let heights: [CGFloat] = [0.5, 1.0, 0.72]

    for (i, h) in heights.enumerated() {
        let x = margin + CGFloat(i) * (barWidth + barSpacing)
        let barHeight = barAreaHeight * h
        let y = margin + (barAreaHeight - barHeight)
        let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth * 0.15, yRadius: barWidth * 0.15)
        barPath.fill()
    }

    // Small dollar sign in top right
    let dollarFont = NSFont.systemFont(ofSize: s * 0.16, weight: .bold)
    let dollarAttrs: [NSAttributedString.Key: Any] = [
        .font: dollarFont,
        .foregroundColor: NSColor.white.withAlphaComponent(0.6),
    ]
    let dollarStr = "$" as NSString
    let dollarSize = dollarStr.size(withAttributes: dollarAttrs)
    dollarStr.draw(
        at: NSPoint(x: s - margin * 0.6 - dollarSize.width, y: s - margin * 0.7 - dollarSize.height),
        withAttributes: dollarAttrs
    )

    image.unlockFocus()
    return image
}

func saveAsPNG(_ image: NSImage, path: String, pixelSize: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(
        in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

// Icon sizes needed for macOS app icon
let sizes: [(points: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

let basePath = "ClaudeUsageBar/Resources/Assets.xcassets/AppIcon.appiconset"
let image = generateIcon(size: 1024)

for size in sizes {
    let pixels = size.points * size.scale
    let filename = "icon_\(size.points)x\(size.points)@\(size.scale)x.png"
    let path = "\(basePath)/\(filename)"
    saveAsPNG(image, path: path, pixelSize: pixels)
    print("Generated \(filename) (\(pixels)x\(pixels) px)")
}

print("Done!")
