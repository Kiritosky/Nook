//
//  SidebarView.swift
//  Nook
//

import SwiftUI
import SwiftData

enum SidebarItem: Hashable {
    case alle
    case favoriten
    case angeheftet
    case sprache(Language)
    case customSprache(String)
    case projekt(String)
    case tag(String)
    case thema(String)
    case papierkorb
    // Einstiegspunkte zum „Reingehen" (Bibliotheken) – keine Inline-Listen
    case projekteBrowser
    case themenBrowser
    case tagsBrowser
}

/// Ziel beim Reingehen in eine Bibliothek (Projekt/Thema/Tag) – für NavigationStack.
enum BrowserZiel: Hashable {
    case projekt(String)
    case thema(String)
    case tag(String)

    var alsSidebarItem: SidebarItem {
        switch self {
        case .projekt(let n): return .projekt(n)
        case .thema(let n):   return .thema(n)
        case .tag(let n):     return .tag(n)
        }
    }
}

struct SidebarView: View {
    @Binding var auswahl: SidebarItem?
    @Query(filter: #Predicate<Snippet> { $0.deletedAt == nil })
    private var alleSnippets: [Snippet]
    @Query(filter: #Predicate<Snippet> { $0.deletedAt != nil })
    private var papierkorbSnippets: [Snippet]
    @Query(sort: \CustomLanguage.name) private var customLanguages: [CustomLanguage]
    @Query(sort: \Projekt.name) private var projekte: [Projekt]


    private func anzahl(_ item: SidebarItem) -> Int {
        switch item {
        case .alle:                    return alleSnippets.count
        case .favoriten:               return alleSnippets.filter { $0.isFavorite }.count
        case .angeheftet:              return alleSnippets.filter { $0.isPinned }.count
        case .sprache(let lang):       return alleSnippets.filter { $0.language == lang && $0.languageOverride == nil }.count
        case .customSprache(let name): return alleSnippets.filter { $0.languageOverride == name }.count
        case .projekt(let proj):       return alleSnippets.filter { $0.project == proj }.count
        case .tag(let tag):            return alleSnippets.filter { $0.tags.contains(tag) }.count
        case .thema(let thema):        return alleSnippets.filter { $0.topic == thema }.count
        case .papierkorb:              return papierkorbSnippets.count
        case .projekteBrowser:         return alleProjektNamen.count
        case .themenBrowser:           return alleThemen.count
        case .tagsBrowser:             return alleTags.count
        }
    }

    // Alle Projektnamen (Objekte + verwaiste Strings), dedupliziert
    private var alleProjektNamen: [String] {
        Array(Set(projekte.map(\.name) + orphanProjekte)).sorted()
    }

    private var projektNamenMitObjekt: Set<String> { Set(projekte.map(\.name)) }

    // Projekt-Strings aus Snippets ohne passendes Projekt-Objekt
    private var orphanProjekte: [String] {
        Array(Set(
            alleSnippets.compactMap { $0.project }
                .filter { !$0.isEmpty && !projektNamenMitObjekt.contains($0) }
        )).sorted()
    }

    private var alleTags: [String] {
        Array(Set(alleSnippets.flatMap { $0.tags })).sorted()
    }

    private var alleThemen: [String] {
        Array(Set(alleSnippets.map { $0.topic }.filter { !$0.isEmpty })).sorted()
    }

    private var topSprache: (name: String, farbe: Color)? {
        let z = Dictionary(grouping: alleSnippets, by: { $0.effectiveLanguageName }).mapValues { $0.count }
        guard let top = z.max(by: { $0.value < $1.value }) else { return nil }
        return (top.key, Language(rawValue: top.key)?.farbe ?? .indigo)
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $auswahl) {

                // MARK: Bibliothek
                Section {
                    SidebarZeile(symbol: "square.stack.3d.up.fill", farbe: .blue,
                                 titel: "Alle Snippets", anzahl: anzahl(.alle))
                        .tag(SidebarItem.alle)

                    SidebarZeile(symbol: "star.fill", farbe: .yellow,
                                 titel: "Favoriten", anzahl: anzahl(.favoriten))
                        .tag(SidebarItem.favoriten)

                    let angeheftetAnzahl = anzahl(.angeheftet)
                    if angeheftetAnzahl > 0 {
                        SidebarZeile(symbol: "pin.fill", farbe: .orange,
                                     titel: "Angeheftet", anzahl: angeheftetAnzahl)
                            .tag(SidebarItem.angeheftet)
                    }
                } header: { sectionHeader("Bibliothek") }

                // MARK: Sprachen
                Section {
                    ForEach(Language.allCases, id: \.self) { sprache in
                        let n = anzahl(.sprache(sprache))
                        if n > 0 {
                            SidebarZeile(symbol: sprache.symbolName, farbe: sprache.farbe,
                                         titel: sprache.rawValue, anzahl: n)
                                .tag(SidebarItem.sprache(sprache))
                        }
                    }
                    ForEach(customLanguages) { lang in
                        SidebarZeile(symbol: lang.symbolName, farbe: .indigo,
                                     titel: lang.name, anzahl: anzahl(.customSprache(lang.name)))
                            .tag(SidebarItem.customSprache(lang.name))
                    }
                } header: { sectionHeader("Sprachen") }

                // MARK: Bibliotheken (Einstiegspunkte – kein Inline-Listing)
                Section {
                    if !alleProjektNamen.isEmpty {
                        BibliothekZeile(symbol: "folder.fill", farbe: .brown,
                                        titel: "Projekte", anzahl: anzahl(.projekteBrowser))
                            .tag(SidebarItem.projekteBrowser)
                    }
                    if !alleThemen.isEmpty {
                        BibliothekZeile(symbol: "text.book.closed.fill", farbe: .teal,
                                        titel: "Themen", anzahl: anzahl(.themenBrowser))
                            .tag(SidebarItem.themenBrowser)
                    }
                    if !alleTags.isEmpty {
                        BibliothekZeile(symbol: "number", farbe: .purple,
                                        titel: "Tags", anzahl: anzahl(.tagsBrowser))
                            .tag(SidebarItem.tagsBrowser)
                    }
                } header: { sectionHeader("Durchstöbern") }

                // MARK: Papierkorb
                if !papierkorbSnippets.isEmpty {
                    Section {
                        SidebarZeile(symbol: "trash.fill", farbe: .gray,
                                     titel: "Papierkorb", anzahl: papierkorbSnippets.count)
                            .tag(SidebarItem.papierkorb)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(maxHeight: .infinity)

            if !alleSnippets.isEmpty {
                Divider()
                statsFooter
            }
        }
        .navigationTitle("Nook")
        .navigationSplitViewColumnWidth(min: 200, ideal: 230)
    }

    private var statsFooter: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(alleSnippets.count) Snippet\(alleSnippets.count == 1 ? "" : "s")")
                    .font(.caption).fontWeight(.medium)
                if let top = topSprache {
                    HStack(spacing: 4) {
                        Circle().fill(top.farbe).frame(width: 5, height: 5)
                        Text("Meist: \(top.name)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(topLanguages(limit: 5), id: \.0) { name, farbe in
                    Circle().fill(farbe).frame(width: 7, height: 7).help(name)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(.bar)
    }

    private func topLanguages(limit: Int) -> [(String, Color)] {
        Dictionary(grouping: alleSnippets, by: { $0.effectiveLanguageName })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, Language(rawValue: $0.key)?.farbe ?? .indigo) }
    }

    @ViewBuilder
    private func sectionHeader(_ titel: String) -> some View {
        Text(LocalizedStringKey(titel))
            .font(.caption2).fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase).tracking(0.8)
    }
}
