//
//  ContentView.swift
//  Nook
//
//  Created by Lasse Gröne on 20.07.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var sidebarAuswahl: SidebarItem? = .alle
    @State private var selectedSnippet: Snippet?
    @State private var addSnippetAnzeigen = false

    var body: some View {
        NavigationSplitView {
            SidebarView(auswahl: $sidebarAuswahl)
        } content: {
            SnippetListView(
                sidebarItem: sidebarAuswahl ?? .alle,
                selectedSnippet: $selectedSnippet,
                addSnippetAnzeigen: $addSnippetAnzeigen
            )
        } detail: {
            if let snippet = selectedSnippet {
                SnippetDetailView(snippet: snippet)
            } else {
                ContentUnavailableView(
                    "Kein Snippet ausgewählt",
                    systemImage: "doc.text",
                    description: Text("Wähle ein Snippet aus der Liste aus.")
                )
            }
        }
        .sheet(isPresented: $addSnippetAnzeigen) {
            AddSnippetView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Snippet.self, inMemory: true)
}
