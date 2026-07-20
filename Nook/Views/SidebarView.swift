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
            Section("Bibliothek") {
                Label("Alle Snippets", systemImage: "square.stack")
                    .tag(SidebarItem.alle)
                    .badge(anzahl(.alle))
                Label("Favoriten", systemImage: "star")
                    .tag(SidebarItem.favoriten)
                    .badge(anzahl(.favoriten))
            }

            Section("Sprachen") {
                ForEach(Language.allCases, id: \.self) { sprache in
                    Label(sprache.rawValue, systemImage: sprache.symbolName)
                        .tag(SidebarItem.sprache(sprache))
                        .badge(anzahl(.sprache(sprache)))
                }
                ForEach(customLanguages) { lang in
                    Label(lang.name, systemImage: lang.symbolName)
                        .tag(SidebarItem.customSprache(lang.name))
                        .badge(anzahl(.customSprache(lang.name)))
                }
            }

            if !projekte.isEmpty {
                Section("Projekte") {
                    ForEach(projekte, id: \.self) { projekt in
                        Label(projekt, systemImage: "folder")
                            .tag(SidebarItem.projekt(projekt))
                            .badge(anzahl(.projekt(projekt)))
                    }
                }
            }
        }
        .navigationTitle("Nook")
        .navigationSplitViewColumnWidth(min: 185, ideal: 215)
    }
}
