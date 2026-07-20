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
        let basis: [Snippet]
        switch sidebarItem {
        case .alle:              basis = alleSnippets
        case .favoriten:         basis = alleSnippets.filter { $0.isFavorite }
        case .sprache(let lang): basis = alleSnippets.filter { $0.language == lang && $0.languageOverride == nil }
        case .customSprache(let name): basis = alleSnippets.filter { $0.languageOverride == name }
        case .projekt(let proj): basis = alleSnippets.filter { $0.project == proj }
        }

        switch sortierung {
        case .neueste:  return basis.sorted { $0.createdAt > $1.createdAt }
        case .aelteste: return basis.sorted { $0.createdAt < $1.createdAt }
        case .titel:    return basis.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        }
    }

    private var gefilterteSnippets: [Snippet] {
        var ergebnis = basisSnippets
        if let s = schwierigkeitsFilter { ergebnis = ergebnis.filter { $0.difficulty == s } }
        guard !suchtext.isEmpty else { return ergebnis }
        return ergebnis.filter {
            $0.title.localizedCaseInsensitiveContains(suchtext) ||
            $0.topic.localizedCaseInsensitiveContains(suchtext) ||
            $0.effectiveLanguageName.localizedCaseInsensitiveContains(suchtext) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(suchtext)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter-Leiste
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
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
                .padding(.vertical, 7)
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
            .listStyle(.inset)
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
        .navigationSplitViewColumnWidth(min: 260, ideal: 300)
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
                            Text(s.bezeichnung).tag(s)
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
        case .alle:                    return "Alle Snippets"
        case .favoriten:               return "Favoriten"
        case .sprache(let lang):       return lang.rawValue
        case .customSprache(let name): return name
        case .projekt(let proj):       return proj
        }
    }
}

// MARK: - Snippet-Karte

struct SnippetKarte: View {
    let snippet: Snippet
    @AppStorage("showCodePreview") private var showCodePreview: Bool = true

    private var codeVorschau: String {
        snippet.code
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(2)
            .joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Titel + Favorit
            HStack(alignment: .firstTextBaseline) {
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

            // Tags
            HStack(spacing: 5) {
                TagPill(text: snippet.effectiveLanguageName, farbe: .blue)
                SchwierigkeitSterne(stufe: snippet.difficulty)
                if !snippet.topic.isEmpty {
                    Text(snippet.topic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // Code-Vorschau
            if showCodePreview && !codeVorschau.isEmpty {
                Text(codeVorschau)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.vertical, 6)
    }
}
