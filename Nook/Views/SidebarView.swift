//
//  SidebarView.swift
//  Nook
//

import SwiftUI

// Navigations-Zustände der Sidebar
enum SidebarItem: Hashable {
    case alle
    case favoriten
    case sprache(Language)
}

struct SidebarView: View {
    @Binding var auswahl: SidebarItem?

    var body: some View {
        List(selection: $auswahl) {
            Section("Bibliothek") {
                Label("Alle Snippets", systemImage: "square.stack")
                    .tag(SidebarItem.alle)
                Label("Favoriten", systemImage: "star")
                    .tag(SidebarItem.favoriten)
            }

            Section("Sprachen") {
                ForEach(Language.allCases, id: \.self) { sprache in
                    Label(sprache.rawValue, systemImage: sprache.symbolName)
                        .tag(SidebarItem.sprache(sprache))
                }
            }
        }
        .navigationTitle("Nook")
        .navigationSplitViewColumnWidth(min: 180, ideal: 210)
    }
}
