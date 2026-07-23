//
//  SnippetBildExport.swift
//  Nook
//
//  Phase 2 – Feature 7: Snippet als schön gerendertes Bild (Carbon-Stil)
//  exportieren – zum Speichern als PNG oder Kopieren in die Zwischenablage,
//  für Docs, Slack & Co.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Bild-Karte (Carbon-Stil)

/// Die gerenderte Code-Karte: getönter Rahmen, „Fenster" mit Ampel-Punkten,
/// Titel und syntax-gehighlighteter Code. Rein statisch → via ImageRenderer
/// in ein Bild überführbar.
struct SnippetBildKarte: View {
    let snippet: Snippet
    let theme: SyntaxTheme
    var fontSize: Double = 13

    private var titel: String {
        snippet.title.isEmpty ? snippet.effectiveLanguageName : snippet.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Titelleiste
            HStack(spacing: 7) {
                Circle().fill(Color(hex: "FF5F57")).frame(width: 12, height: 12)
                Circle().fill(Color(hex: "FFBD2E")).frame(width: 12, height: 12)
                Circle().fill(Color(hex: "28CA41")).frame(width: 12, height: 12)
                Spacer(minLength: 12)
                Text(titel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.isLight ? .black.opacity(0.55) : .white.opacity(0.55))
                    .lineLimit(1)
                Spacer(minLength: 12)
                Color.clear.frame(width: 44, height: 1)   // balanciert die Ampel-Punkte
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.white.opacity(theme.isLight ? 0.06 : 0.07))
                .frame(height: 1)

            // Code
            Text(SyntaxHighlighter.highlight(
                code: snippet.code,
                language: snippet.effectiveHighlightName,
                theme: theme,
                fontSize: fontSize
            ))
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .background(theme.hintergrundFarbe)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        .frame(width: 720, alignment: .leading)
        .padding(38)
        .background(
            LinearGradient(
                colors: [snippet.akzentFarbe.opacity(0.55), snippet.akzentFarbe.opacity(0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 4) {
                Image(systemName: "curlybraces").font(.system(size: 10, weight: .bold))
                Text("Nook").font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.75))
            .padding(16)
        }
    }
}

// MARK: - Export-Aktionen

enum SnippetBildExport {

    @MainActor
    private static func cgImage(_ snippet: Snippet, theme: SyntaxTheme, scale: CGFloat = 2) -> CGImage? {
        let renderer = ImageRenderer(content: SnippetBildKarte(snippet: snippet, theme: theme))
        renderer.scale = scale
        return renderer.cgImage
    }

    /// PNG-Datei über einen Speichern-Dialog ablegen. Gibt Erfolg zurück.
    @MainActor
    @discardableResult
    static func speichern(_ snippet: Snippet, theme: SyntaxTheme) -> Bool {
        guard let cg = cgImage(snippet, theme: theme) else { return false }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(dateiname(snippet)).png"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        let rep = NSBitmapImageRep(cgImage: cg)
        guard let png = rep.representation(using: .png, properties: [:]) else { return false }
        try? png.write(to: url, options: .atomic)
        return true
    }

    /// Bild in die Zwischenablage kopieren. Gibt Erfolg zurück.
    @MainActor
    @discardableResult
    static func kopieren(_ snippet: Snippet, theme: SyntaxTheme) -> Bool {
        guard let cg = cgImage(snippet, theme: theme) else { return false }
        let bild = NSImage(cgImage: cg, size: NSSize(width: cg.width / 2, height: cg.height / 2))
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.writeObjects([bild])
    }

    private static func dateiname(_ snippet: Snippet) -> String {
        let basis = snippet.title.isEmpty ? snippet.effectiveLanguageName : snippet.title
        let sauber = basis.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return sauber.isEmpty ? "Nook-Snippet" : "Nook-\(sauber)"
    }
}
