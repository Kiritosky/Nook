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

    var body: some View {
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
                Text("Bibliothek")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            // MARK: Sprachen
            Section {
                ForEach(Language.allCases, id: \.self) { sprache in
                    SidebarZeile(symbol: sprache.symbolName, farbe: sprache.farbe,
                                 titel: sprache.rawValue, anzahl: anzahl(.sprache(sprache)))
                        .tag(SidebarItem.sprache(sprache))
                }
                ForEach(customLanguages) { lang in
                    SidebarZeile(symbol: lang.symbolName, farbe: .indigo,
                                 titel: lang.name, anzahl: anzahl(.customSprache(lang.name)))
                        .tag(SidebarItem.customSprache(lang.name))
                }
            } header: {
                Text("Sprachen")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
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
                    Text("Projekte")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Nook")
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    }
}
