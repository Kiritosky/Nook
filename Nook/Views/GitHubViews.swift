//
//  GitHubViews.swift
//  Nook
//
//  Phase 2 – Feature 8: UI zum Anmelden (Device Flow) und zum Veröffentlichen
//  eines Snippets als Gist.
//

import SwiftUI
import AppKit

// MARK: - Konto-Ansicht (Einstellungen)

struct GitHubKontoView: View {
    @State private var konto = GitHubKonto.shared

    var body: some View {
        if !konto.istKonfiguriert {
            Label("GitHub ist noch nicht eingerichtet (Client-ID fehlt in GitHubClient.swift).",
                  systemImage: "exclamationmark.triangle")
                .font(.caption).foregroundStyle(.secondary)
        } else if let user = konto.benutzer {
            LabeledContent("Angemeldet") {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    Text("@\(user)").foregroundStyle(.secondary)
                }
            }
            Button("Abmelden", role: .destructive) { konto.abmelden() }
        } else if let code = konto.geräteCode {
            VStack(alignment: .leading, spacing: 8) {
                Text("Gib diesen Code auf **github.com/login/device** ein:")
                    .font(.callout)
                Text(code.userCode)
                    .font(.system(.title, design: .monospaced)).fontWeight(.semibold)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                Text("Der Browser wurde geöffnet. Warte auf Bestätigung …")
                    .font(.caption).foregroundStyle(.secondary)
                ProgressView().controlSize(.small)
            }
            .padding(.vertical, 4)
        } else {
            Button {
                Task { await konto.anmelden() }
            } label: {
                Label(konto.laeuftAnmeldung ? "Verbinde …" : "Mit GitHub anmelden",
                      systemImage: "person.badge.key")
            }
            .disabled(konto.laeuftAnmeldung)
            if let f = konto.fehler {
                Label(f, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
            }
            Text("Meldet dich sicher über den Browser an (Device Flow). Nook speichert nur ein Zugriffstoken im Schlüsselbund — nie dein Passwort.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Gist veröffentlichen (Sheet aus der Detailansicht)

struct GistVeröffentlichenSheet: View {
    let snippet: Snippet
    @Environment(\.dismiss) private var dismiss
    @State private var konto = GitHubKonto.shared

    @State private var öffentlich = false
    @State private var läuft = false
    @State private var ergebnis: URL?
    @State private var fehler: String?

    private var dateiname: String {
        let basis = snippet.title.isEmpty ? "snippet" : snippet.title
        let sauber = basis.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: "-")
        return "\(sauber.isEmpty ? "snippet" : sauber).\(dateiendung)"
    }

    private var dateiendung: String {
        switch snippet.effectiveHighlightName {
        case "swift": return "swift"; case "python": return "py"
        case "javascript": return "js"; case "typescript": return "ts"
        case "jsx": return "jsx"; case "java": return "java"; case "kotlin": return "kt"
        case "c": return "c"; case "cpp": return "cpp"; case "csharp": return "cs"
        case "ruby": return "rb"; case "php": return "php"; case "go": return "go"
        case "rust": return "rs"; case "sql": return "sql"; case "json": return "json"
        case "yaml": return "yml"; case "bash": return "sh"; case "html": return "html"
        case "css": return "css"; case "markdown": return "md"; default: return "txt"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.forward.square")
                    .font(.title2).foregroundStyle(Color.accentColor)
                Text("Als Gist veröffentlichen").font(.headline)
                Spacer()
            }

            if konto.benutzer == nil {
                Text("Dafür musst du dich erst mit GitHub anmelden (Einstellungen → Allgemein → GitHub).")
                    .font(.callout).foregroundStyle(.secondary)
            } else if let url = ergebnis {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Veröffentlicht als @\(konto.benutzer ?? "")", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(url.absoluteString).font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary).textSelection(.enabled).lineLimit(1)
                    HStack {
                        Button { NSWorkspace.shared.open(url) } label: { Label("Öffnen", systemImage: "safari") }
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url.absoluteString, forType: .string)
                        } label: { Label("Link kopieren", systemImage: "doc.on.doc") }
                    }
                }
            } else {
                LabeledContent("Datei") { Text(dateiname).foregroundStyle(.secondary) }
                Toggle("Öffentlicher Gist", isOn: $öffentlich)
                Text(öffentlich
                     ? "Für alle sichtbar und auffindbar."
                     : "Nicht gelistet (secret) — nur wer den Link hat, sieht ihn.")
                    .font(.caption).foregroundStyle(.secondary)
                if let f = fehler {
                    Label(f, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                }
            }

            Divider()
            HStack {
                Button("Schließen") { dismiss() }
                Spacer()
                if konto.benutzer != nil && ergebnis == nil {
                    Button {
                        Task { await veröffentliche() }
                    } label: {
                        Label(läuft ? "Veröffentliche …" : "Veröffentlichen", systemImage: "arrow.up")
                    }
                    .buttonStyle(.borderedProminent).disabled(läuft)
                }
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private func veröffentliche() async {
        läuft = true; fehler = nil
        defer { läuft = false }
        do {
            let url = try await konto.veröffentliche(
                name: dateiname,
                inhalt: snippet.code,
                beschreibung: snippet.title.isEmpty ? snippet.effectiveLanguageName : snippet.title,
                öffentlich: öffentlich
            )
            ergebnis = url
        } catch {
            fehler = error.localizedDescription
        }
    }
}
