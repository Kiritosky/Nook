//
//  SnippetListView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct SnippetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Snippet.createdAt, order: .reverse) private var alleSnippets: [Snippet]

    let sidebarItem: SidebarItem
    @Binding var selectedSnippet: Snippet?
    @Binding var addSnippetAnzeigen: Bool

    @State private var suchtext = ""

    // Gefilterte Snippets je nach Sidebar-Auswahl und Suchtext
    private var gefilterteSnippets: [Snippet] {
        let basis: [Snippet]
        switch sidebarItem {
        case .alle:
            basis = alleSnippets
        case .favoriten:
            basis = alleSnippets.filter { $0.isFavorite }
        case .sprache(let lang):
            basis = alleSnippets.filter { $0.language == lang }
        }

        guard !suchtext.isEmpty else { return basis }
        return basis.filter {
            $0.title.localizedCaseInsensitiveContains(suchtext) ||
            $0.topic.localizedCaseInsensitiveContains(suchtext) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(suchtext)
        }
    }

    var body: some View {
        List(gefilterteSnippets, selection: $selectedSnippet) { snippet in
            SnippetKarte(snippet: snippet)
                .tag(snippet)
        }
        .searchable(text: $suchtext, prompt: "Suchen...")
        .navigationTitle(titelFuerAuswahl)
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addSnippetAnzeigen = true
                } label: {
                    Label("Snippet hinzufügen", systemImage: "plus")
                }
            }
        }
        .overlay {
            if gefilterteSnippets.isEmpty {
                ContentUnavailableView(
                    suchtext.isEmpty ? "Keine Snippets" : "Keine Ergebnisse",
                    systemImage: suchtext.isEmpty ? "doc.text" : "magnifyingglass",
                    description: Text(suchtext.isEmpty ? "Erstelle dein erstes Snippet mit dem + Button." : "Versuche einen anderen Suchbegriff.")
                )
            }
        }
    }

    private var titelFuerAuswahl: String {
        switch sidebarItem {
        case .alle:              return "Alle Snippets"
        case .favoriten:         return "Favoriten"
        case .sprache(let lang): return lang.rawValue
        }
    }
}

// Kompakte Snippet-Vorschau in der Liste
struct SnippetKarte: View {
    let snippet: Snippet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(snippet.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if snippet.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            HStack(spacing: 6) {
                TagPill(text: snippet.language.rawValue, farbe: .blue)
                if !snippet.topic.isEmpty {
                    Text(snippet.topic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
