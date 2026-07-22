//
//  SidebarView.swift
//  Nook
//

import SwiftUI
import SwiftData

enum SidebarItem: Hashable {
    case alle
    case favoriten
    case sprache(Language)
    case customSprache(String)
    case projekt(String)
}

struct SidebarView: View {
    @Binding var auswahl: SidebarItem?
    @Query private var alleSnippets: [Snippet]
    @Query(sort: \CustomLanguage.name) private var customLanguages: [CustomLanguage]

    private func anzahl(_ item: SidebarItem) -> Int {
        switch item {
        case .alle:                    return alleSnippets.count
        case .favoriten:               return alleSnippets.filter { $0.isFavorite }.count
        case .sprache(let lang):       return alleSnippets.filter { $0.language == lang && $0.languageOverride == nil }.count
        case .customSprache(let name): return alleSnippets.filter { $0.languageOverride == name }.count
        case .projekt(let proj):       return alleSnippets.filter { $0.project == proj }.count
        }
    }

    private var projekte: [String] {
        Array(Set(alleSnippets.compactMap { $0.project }.filter { !$0.isEmpty })).sorted()
    }

    // Meistverwendete Sprache für Stats-Footer
    private var topSprache: (name: String, farbe: Color)? {
        let zaehlungen = Dictionary(grouping: alleSnippets, by: { $0.effectiveLanguageName })
            .mapValues { $0.count }
        guard let top = zaehlungen.max(by: { $0.value < $1.value }) else { return nil }
        let farbe = Language(rawValue: top.key)?.farbe ?? .indigo
        return (top.key, farbe)
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
                } header: {
                    sectionHeader("Bibliothek")
                }

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
                } header: {
                    sectionHeader("Sprachen")
                }

                // MARK: Projekte
                if !projekte.isEmpty {
                    Section {
                        ForEach(projekte, id: \.self) { projekt in
                            SidebarZeile(symbol: "folder.fill", farbe: .brown,
                                         titel: projekt, anzahl: anzahl(.projekt(projekt)))
                                .tag(SidebarItem.projekt(projekt))
                        }
                    } header: {
                        sectionHeader("Projekte")
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(maxHeight: .infinity)

            // Stats-Footer
            if !alleSnippets.isEmpty {
                Divider()
                statsFooter
            }
        }
        .navigationTitle("Nook")
        .navigationSplitViewColumnWidth(min: 200, ideal: 225)
    }

    private var statsFooter: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(alleSnippets.count) Snippet\(alleSnippets.count == 1 ? "" : "s")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                if let top = topSprache {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(top.farbe)
                            .frame(width: 5, height: 5)
                        Text("Meist: \(top.name)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()

            // Mini-Sprach-Verteilung als Punkte
            HStack(spacing: 3) {
                ForEach(topLanguages(limit: 5), id: \.0) { name, farbe in
                    Circle()
                        .fill(farbe)
                        .frame(width: 7, height: 7)
                        .help(name)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
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
        Text(titel)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
