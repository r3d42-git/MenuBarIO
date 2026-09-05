#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate_dmg_background.swift OUTPUT_PNG\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 760, height: 560)
guard let bitmapContext = CGContext(
    data: nil,
    width: Int(size.width),
    height: Int(size.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Could not create the DMG background bitmap.\n", stderr)
    exit(1)
}
let graphicsContext = NSGraphicsContext(cgContext: bitmapContext, flipped: false)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawCentered(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let textSize = (text as NSString).size(withAttributes: attributes)
    (text as NSString).draw(
        at: NSPoint(x: (size.width - textSize.width) / 2, y: y),
        withAttributes: attributes
    )
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let bounds = NSRect(origin: .zero, size: size)
NSGradient(
    starting: color(24, 32, 38),
    ending: color(13, 18, 22)
)?.draw(in: bounds, angle: 90)

color(121, 196, 255, 0.12).setFill()
NSBezierPath(ovalIn: NSRect(x: -110, y: 370, width: 340, height: 340)).fill()
color(70, 128, 175, 0.10).setFill()
NSBezierPath(ovalIn: NSRect(x: 535, y: -105, width: 330, height: 330)).fill()

let divider = NSBezierPath()
divider.move(to: NSPoint(x: 128, y: 439))
divider.line(to: NSPoint(x: 632, y: 439))
divider.lineWidth = 1
color(255, 255, 255, 0.13).setStroke()
divider.stroke()

drawCentered(
    "MenuBarIO installieren",
    y: 492,
    font: .systemFont(ofSize: 22, weight: .semibold),
    color: color(244, 247, 250)
)
drawCentered(
    "Ziehe die App nach Programme",
    y: 464,
    font: .systemFont(ofSize: 14, weight: .regular),
    color: color(184, 197, 207)
)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 329, y: 345))
arrow.line(to: NSPoint(x: 438, y: 345))
arrow.lineWidth = 4
arrow.lineCapStyle = .round
color(121, 196, 255, 0.86).setStroke()
arrow.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 438, y: 345))
arrowHead.line(to: NSPoint(x: 417, y: 358))
arrowHead.move(to: NSPoint(x: 438, y: 345))
arrowHead.line(to: NSPoint(x: 417, y: 332))
arrowHead.lineWidth = 4
arrowHead.lineCapStyle = .round
arrowHead.lineJoinStyle = .round
arrowHead.stroke()

for x in [329, 438] {
    let circle = NSBezierPath(ovalIn: NSRect(x: CGFloat(x) - 5, y: 340, width: 10, height: 10))
    color(121, 196, 255, 0.95).setFill()
    circle.fill()
}

color(255, 255, 255, 0.10).setFill()
NSBezierPath(roundedRect: NSRect(x: 82, y: 44, width: 596, height: 1), xRadius: 0.5, yRadius: 0.5).fill()

NSGraphicsContext.restoreGraphicsState()

guard let image = bitmapContext.makeImage() else {
    fputs("Could not create the DMG background image.\n", stderr)
    exit(1)
}
let bitmap = NSBitmapImageRep(cgImage: image)
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not render the DMG background as PNG.\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL, options: .atomic)
