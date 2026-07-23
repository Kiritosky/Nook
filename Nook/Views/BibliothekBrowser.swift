//
//  BibliothekBrowser.swift
//  Nook
//
//  Übersicht zum „Reingehen": zeigt Projekte, Themen oder Tags als durchsuchbare
//  Liste. Auswahl navigiert (NavigationStack) zu den gefilterten Snippets.
//

import SwiftUI
import SwiftData

struct BibliothekBrowser: View {
    enum Art: Hashable { case projekte, themen, tags }
    let art: Art
    /// Wird beim Antippen eines Tags aufgerufen (Tags drillen nicht, sondern setzen die Suche).
    var onTagGewaehlt: (String) -> Void = { _ in }

    @Query(filter: #Predicate<Snippet> { $0.deletedAt == nil })
    private var snippets: [Snippet]
    @Query(sort: \Projekt.name) private var projekte: [Projekt]

    @State private var suche = ""

    private struct Eintrag: Identifiable {
        let id: String
        let symbol: String
        let farbe: Color
        let name: String
        let anzahl: Int
        let ziel: BrowserZiel
    }

    // MARK: Einträge je Art

    private var eintraege: [Eintrag] {
        switch art {
        case .projekte:
            let projektObjekte = Dictionary(uniqueKeysWithValues: projekte.map { ($0.name, $0) })
            let namen = Set(snippets.compactMap { $0.project }.filter { !$0.isEmpty })
            return namen.sorted().map { name in
                let obj = projektObjekte[name]
                return Eintrag(id: name,
                               symbol: obj?.symbolName ?? "folder.fill",
                               farbe: obj?.farbe ?? .brown,
                               name: name,
                               anzahl: snippets.filter { $0.project == name }.count,
                               ziel: .projekt(name))
            }
        case .themen:
            let namen = Set(snippets.flatMap { $0.themen })
            return namen.sorted().map { name in
                Eintrag(id: name, symbol: "text.book.closed.fill", farbe: .teal, name: name,
                        anzahl: snippets.filter { $0.themen.contains(name) }.count, ziel: .thema(name))
            }
        case .tags:
            let namen = Set(snippets.flatMap { $0.tags })
            return namen.sorted().map { name in
                Eintrag(id: name, symbol: "number", farbe: .purple, name: name,
                        anzahl: snippets.filter { $0.tags.contains(name) }.count, ziel: .tag(name))
            }
        }
    }

    private var gefiltert: [Eintrag] {
        guard !suche.isEmpty else { return eintraege }
        return eintraege.filter { $0.name.localizedCaseInsensitiveContains(suche) }
    }

    private var titel: LocalizedStringKey {
        switch art {
        case .projekte: return "Projekte"
        case .themen:   return "Themen"
        case .tags:     return "Tags"
        }
    }

    private var suchePrompt: LocalizedStringKey {
        switch art {
        case .projekte: return "Projekt suchen…"
        case .themen:   return "Thema suchen…"
        case .tags:     return "Tag suchen…"
        }
    }

    var body: some View {
        Group {
            if gefiltert.isEmpty {
                ContentUnavailableView("Keine Treffer", systemImage: "magnifyingglass",
                                       description: Text("Versuche einen anderen Begriff."))
            } else {
                List {
                    ForEach(gefiltert) { e in
                        if art == .tags {
                            // Tags drillen nicht – Klick setzt die Suche auf „#tag"
                            Button { onTagGewaehlt(e.name) } label: {
                                eintragZeile(e)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(value: e.ziel) {
                                eintragZeile(e)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $suche, prompt: suchePrompt)
        .navigationTitle(titel)
    }

    @ViewBuilder
    private func eintragZeile(_ e: Eintrag) -> some View {
        HStack(spacing: 10) {
            FarbIcon(symbol: e.symbol, farbe: e.farbe, groesse: 28)
            Text(art == .tags ? "#\(e.name)" : e.name)
                .font(.body)
                .lineLimit(1)
            Spacer()
            Text("\(e.anzahl)")
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(.secondary).monospacedDigit()
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
