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
    @State private var schwierigkeitsFilter: Int? = nil  // nil = alle

    private var basisSnippets: [Snippet] {
        switch sidebarItem {
        case .alle:
            return alleSnippets
        case .favoriten:
            return alleSnippets.filter { $0.isFavorite }
        case .sprache(let lang):
            return alleSnippets.filter { $0.language == lang }
        case .projekt(let proj):
            return alleSnippets.filter { $0.project == proj }
        }
    }

    private var gefilterteSnippets: [Snippet] {
        var ergebnis = basisSnippets

        if let schwierigkeit = schwierigkeitsFilter {
            ergebnis = ergebnis.filter { $0.difficulty == schwierigkeit }
        }

        guard !suchtext.isEmpty else { return ergebnis }
        return ergebnis.filter {
            $0.title.localizedCaseInsensitiveContains(suchtext) ||
            $0.topic.localizedCaseInsensitiveContains(suchtext) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(suchtext)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter-Leiste
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "Alle", aktiv: schwierigkeitsFilter == nil) {
                        schwierigkeitsFilter = nil
                    }
                    FilterChip(label: "Anfänger", aktiv: schwierigkeitsFilter == 1) {
                        schwierigkeitsFilter = schwierigkeitsFilter == 1 ? nil : 1
                    }
                    FilterChip(label: "Mittel", aktiv: schwierigkeitsFilter == 2) {
                        schwierigkeitsFilter = schwierigkeitsFilter == 2 ? nil : 2
                    }
                    FilterChip(label: "Fortgeschritten", aktiv: schwierigkeitsFilter == 3) {
                        schwierigkeitsFilter = schwierigkeitsFilter == 3 ? nil : 3
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(.bar)

            Divider()

            List(gefilterteSnippets, selection: $selectedSnippet) { snippet in
                SnippetKarte(snippet: snippet)
                    .tag(snippet)
                    .contextMenu {
                        Button {
                            snippet.isFavorite.toggle()
                        } label: {
                            Label(
                                snippet.isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen",
                                systemImage: snippet.isFavorite ? "star.slash" : "star"
                            )
                        }
                        Divider()
                        Button(role: .destructive) {
                            modelContext.delete(snippet)
                            if selectedSnippet == snippet { selectedSnippet = nil }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }
            .overlay {
                if gefilterteSnippets.isEmpty {
                    ContentUnavailableView(
                        suchtext.isEmpty ? "Keine Snippets" : "Keine Ergebnisse",
                        systemImage: suchtext.isEmpty ? "doc.text" : "magnifyingglass",
                        description: Text(
                            suchtext.isEmpty
                                ? "Erstelle dein erstes Snippet mit dem + Button."
                                : "Versuche einen anderen Suchbegriff."
                        )
                    )
                }
            }
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
    }

    private var titelFuerAuswahl: String {
        switch sidebarItem {
        case .alle:              return "Alle Snippets"
        case .favoriten:         return "Favoriten"
        case .sprache(let lang): return lang.rawValue
        case .projekt(let proj): return proj
        }
    }
}

// Filter-Chip für die Filter-Leiste
struct FilterChip: View {
    let label: String
    let aktiv: Bool
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Text(label)
                .font(.caption)
                .fontWeight(aktiv ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(aktiv ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(aktiv ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
