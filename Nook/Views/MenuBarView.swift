//
//  MenuBarView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Query(sort: \Snippet.createdAt, order: .reverse) private var snippets: [Snippet]
    @Environment(\.openWindow) private var openWindow

    @State private var suchtext = ""
    @State private var kopierteID: PersistentIdentifier? = nil

    private var angezeigteSnippets: [Snippet] {
        if suchtext.isEmpty {
            return Array(snippets.prefix(10))
        }
        return snippets.filter {
            $0.title.localizedCaseInsensitiveContains(suchtext) ||
            $0.topic.localizedCaseInsensitiveContains(suchtext) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(suchtext)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Suchfeld
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Snippet suchen...", text: $suchtext)
                    .textFieldStyle(.plain)
                    .font(.body)
                if !suchtext.isEmpty {
                    Button {
                        suchtext = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Snippet-Liste
            if angezeigteSnippets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: suchtext.isEmpty ? "doc.text" : "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
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
                            ) {
                                kopieren(snippet)
                            }
                            if snippet.persistentModelID != angezeigteSnippets.last?.persistentModelID {
                                Divider().padding(.leading, 12)
                            }
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Button {
                    openWindow(id: "hauptfenster")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Nook öffnen", systemImage: "arrow.up.forward.app")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("\(snippets.count) Snippet\(snippets.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320, height: 380)
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

struct MenuBarZeile: View {
    let snippet: Snippet
    let istKopiert: Bool
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snippet.title)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Text(snippet.language.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !snippet.topic.isEmpty {
                            Text("· \(snippet.topic)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                Image(systemName: istKopiert ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(istKopiert ? Color.green : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: istKopiert)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }
}
