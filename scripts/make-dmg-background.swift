#!/usr/bin/env swift
//
//  make-dmg-background.swift
//  Rendert das DMG-Hintergrundbild (Pfeil + Hinweistext) als PNG.
//  Aufruf:  swift make-dmg-background.swift <scale> <output.png>
//  Wird nur beim Aktualisieren des Layouts gebraucht; das Ergebnis (TIFF)
//  liegt committet im Repo, damit die CI nichts rendern muss.
//

import AppKit

let scale = CGFloat(Double(CommandLine.arguments[1]) ?? 1)
let outPath = CommandLine.arguments[2]

let W: CGFloat = 540, H: CGFloat = 380
let px = Int(W * scale), pyi = Int(H * scale)

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: pyi,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)   // Punkte → Retina-korrekt

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Koordinaten in „von oben" (wie dmgbuild) → in AppKit (unten-links) umrechnen.
func y(_ top: CGFloat) -> CGFloat { H - top }

// Hintergrund: sanfter vertikaler Verlauf.
let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.965, green: 0.969, blue: 0.976, alpha: 1),
    NSColor(calibratedRed: 0.914, green: 0.918, blue: 0.933, alpha: 1)
])!
grad.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

// Pfeil von der App (links) zum Programme-Ordner (rechts), auf Icon-Höhe.
let arrowY = y(168)
let x0: CGFloat = 208, x1: CGFloat = 332
let arrowColor = NSColor(calibratedRed: 0.66, green: 0.68, blue: 0.72, alpha: 1)
arrowColor.setStroke()
arrowColor.setFill()

let shaft = NSBezierPath()
shaft.lineWidth = 5
shaft.lineCapStyle = .round
shaft.move(to: NSPoint(x: x0, y: arrowY))
shaft.line(to: NSPoint(x: x1 - 10, y: arrowY))
shaft.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: x1, y: arrowY))
head.line(to: NSPoint(x: x1 - 18, y: arrowY + 11))
head.line(to: NSPoint(x: x1 - 18, y: arrowY - 11))
head.close()
head.fill()

// Titel oben.
func center(_ s: String, font: NSFont, color: NSColor, topY: CGFloat) {
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
    let str = NSAttributedString(string: s, attributes: attrs)
    let size = str.size()
    str.draw(at: NSPoint(x: (W - size.width) / 2, y: y(topY) - size.height))
}

center("Nook installieren",
       font: .systemFont(ofSize: 22, weight: .semibold),
       color: NSColor(calibratedWhite: 0.22, alpha: 1),
       topY: 40)

center("Symbol in den Programme-Ordner ziehen",
       font: .systemFont(ofSize: 13, weight: .regular),
       color: NSColor(calibratedWhite: 0.55, alpha: 1),
       topY: 316)

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("geschrieben: \(outPath) (\(px)×\(pyi))")
