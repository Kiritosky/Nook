//
//  SnippetListView.swift
//  Nook
//

import SwiftUI
import SwiftData

enum Sortierung: String, CaseIterable {
    case neueste  = "neueste"
    case aelteste = "aelteste"
    case titel    = "titel"

    var bezeichnung: String {
        switch self {
        case .neueste:  return "Neueste zuerst"
        case .aelteste: return "Älteste zuerst"
        case .titel:    return "Nach Titel"
        }
    }

    var symbolName: String {
        switch self {
        case .neueste:  return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .aelteste: return "clock"
        case .titel:    return "textformat"
        }
    }
}

struct SnippetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var alleSnippets: [Snippet]

    let sidebarItem: SidebarItem
    @Binding var selectedSnippet: Snippet?
    @Binding var addSnippetAnzeigen: Bool

    @State private var suchtext = ""
    @State private var schwierigkeitsFilter: Int? = nil
    @AppStorage("snippetSortierung") private var sortierung: Sortierung = .neueste

    private var basisSnippets: [Snippet] {
        let gefiltert: [Snippet]
        switch sidebarItem {
        case .alle:
            gefiltert = alleSnippets
        case .favoriten:
            gefiltert = alleSnippets.filter { $0.isFavorite }
        case .sprache(let lang):
            gefiltert = alleSnippets.filter { $0.language == lang }
        case .projekt(let proj):
            gefiltert = alleSnippets.filter { $0.project == proj }
        }

        switch sortierung {
        case .neueste:
            return gefiltert.sorted { $0.createdAt > $1.createdAt }
        case .aelteste:
            return gefiltert.sorted { $0.createdAt < $1.createdAt }
        case .titel:
            return gefiltert.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
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
                .keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Sortierung", selection: $sortierung) {
                        ForEach(Sortierung.allCases, id: \.self) { s in
                            Label(s.bezeichnung, systemImage: s.symbolName).tag(s)
                        }
                    }
                } label: {
                    Label("Sortierung", systemImage: "arrow.up.arrow.down")
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
