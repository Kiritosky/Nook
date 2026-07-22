//
//  MenuBarView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Query(sort: \Snippet.createdAt, order: .reverse) private var snippets: [Snippet]
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext

    @State private var suchtext = ""
    @State private var kopierteID: PersistentIdentifier? = nil
    @State private var clipboardSnippetAnzeigen = false

    private var clipboardText: String? {
        let text = NSPasteboard.general.string(forType: .string)
        return (text?.isEmpty == false) ? text : nil
    }

    private var angezeigteSnippets: [Snippet] {
        if suchtext.isEmpty { return Array(snippets.prefix(10)) }
        return snippets.filter {
            $0.title.localizedCaseInsensitiveContains(suchtext) ||
            $0.topic.localizedCaseInsensitiveContains(suchtext) ||
            $0.effectiveLanguageName.localizedCaseInsensitiveContains(suchtext) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(suchtext)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Suchfeld
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Snippet suchen...", text: $suchtext)
                    .textFieldStyle(.plain)
                if !suchtext.isEmpty {
                    Button { suchtext = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Snippet-Liste
            if angezeigteSnippets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: suchtext.isEmpty ? "curlybraces" : "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text(suchtext.isEmpty ? "Noch keine Snippets" : "Keine Treffer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(angezeigteSnippets) { snippet in
                            MenuBarZeile(
                                snippet: snippet,
                                istKopiert: kopierteID == snippet.persistentModelID
                            ) { kopieren(snippet) }

                            if snippet.persistentModelID != angezeigteSnippets.last?.persistentModelID {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                }
            }

            Divider()

            // Aktionen
            VStack(spacing: 0) {
                // Clipboard-Aktion (nur sichtbar wenn Clipboard Text enthält)
                if let clip = clipboardText {
                    Button {
                        clipboardSnippetAnzeigen = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard")
                                .frame(width: 20)
                                .foregroundStyle(.teal)
                            Text("Snippet aus Zwischenablage")
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(clip.prefix(20) + (clip.count > 20 ? "…" : ""))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                }

                // Footer-Zeile
                HStack(spacing: 0) {
                    Button {
                        openWindow(id: "hauptfenster")
                        NSApp.setActivationPolicy(.regular)
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "macwindow")
                            Text("Öffnen")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    Spacer()

                    Text("\(snippets.count) Snippets")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        HStack(spacing: 5) {
                            Text("Beenden")
                            Image(systemName: "power")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 340, height: 400)
        .sheet(isPresented: $clipboardSnippetAnzeigen) {
            AddSnippetView(initialCode: clipboardText ?? "")
        }
    }

    private func kopieren(_ snippet: Snippet) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)
        kopierteID = snippet.persistentModelID
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            kopierteID = nil
        }
    }
}

// MARK: - Menu Bar Zeile

struct MenuBarZeile: View {
    let snippet: Snippet
    let istKopiert: Bool
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 10) {
                FarbIcon(symbol: snippet.language.symbolName, farbe: snippet.akzentFarbe, groesse: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(snippet.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    Text(snippet.effectiveLanguageName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: istKopiert ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(istKopiert ? Color.green : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: istKopiert)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
