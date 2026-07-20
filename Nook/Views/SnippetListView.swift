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
        case .alle:                    basis = alleSnippets
        case .favoriten:               basis = alleSnippets.filter { $0.isFavorite }
        case .sprache(let lang):       basis = alleSnippets.filter { $0.language == lang && $0.languageOverride == nil }
        case .customSprache(let name): basis = alleSnippets.filter { $0.languageOverride == name }
        case .projekt(let proj):       basis = alleSnippets.filter { $0.project == proj }
        }
        switch sortierung {
        case .neueste:  return basis.sorted { $0.createdAt > $1.createdAt }
        case .aelteste: return basis.sorted { $0.createdAt < $1.createdAt }
        case .titel:    return basis.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    private var gefilterteSnippets: [Snippet] {
        var r = basisSnippets
        if let s = schwierigkeitsFilter { r = r.filter { $0.difficulty == s } }
        guard !suchtext.isEmpty else { return r }
        return r.filter {
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
                    FilterChip(label: "Alle", aktiv: schwierigkeitsFilter == nil) { schwierigkeitsFilter = nil }
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

            // Snippet-Liste
            if gefilterteSnippets.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(gefilterteSnippets) { snippet in
                            SnippetKarte(snippet: snippet, istAusgewaehlt: selectedSnippet == snippet)
                                .onTapGesture { selectedSnippet = snippet }
                                .contextMenu {
                                    Button {
                                        snippet.isFavorite.toggle()
                                    } label: {
                                        Label(snippet.isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten",
                                              systemImage: snippet.isFavorite ? "star.slash" : "star")
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
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
            }
        }
        .searchable(text: $suchtext, prompt: "Suchen...")
        .navigationTitle(titelFuerAuswahl)
        .navigationSplitViewColumnWidth(min: 270, ideal: 310)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { addSnippetAnzeigen = true } label: {
                    Label("Hinzufügen", systemImage: "plus")
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

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: suchtext.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.quaternary)
            Text(suchtext.isEmpty ? "Keine Snippets" : "Keine Treffer")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(suchtext.isEmpty ? "Erstelle dein erstes Snippet mit ⌘N." : "Versuche einen anderen Suchbegriff.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Snippet-Karte

struct SnippetKarte: View {
    let snippet: Snippet
    let istAusgewaehlt: Bool
    @AppStorage("showCodePreview") private var showCodePreview: Bool = true

    private var codeVorschau: String {
        snippet.code
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(2)
            .joined(separator: "\n")
    }

    var body: some View {
        HStack(spacing: 0) {
            // Farbiger Akzentbalken links
            RoundedRectangle(cornerRadius: 2)
                .fill(snippet.akzentFarbe.gradient)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                // Zeile 1: Titel + Favorit
                HStack(alignment: .firstTextBaseline) {
                    Text(snippet.title)
                        .font(.system(.subheadline, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if snippet.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                }

                // Zeile 2: Sprache + Schwierigkeit + Thema
                HStack(spacing: 5) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(snippet.akzentFarbe)
                            .frame(width: 7, height: 7)
                        Text(snippet.effectiveLanguageName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(snippet.akzentFarbe)
                    }

                    SchwierigkeitSterne(stufe: snippet.difficulty)

                    if !snippet.topic.isEmpty {
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text(snippet.topic)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Zeile 3: Code-Vorschau
                if showCodePreview && !codeVorschau.isEmpty {
                    Text(codeVorschau)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(istAusgewaehlt
                      ? snippet.akzentFarbe.opacity(0.12)
                      : Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(istAusgewaehlt ? snippet.akzentFarbe.opacity(0.4) : Color.primary.opacity(0.07), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: istAusgewaehlt)
    }
}
