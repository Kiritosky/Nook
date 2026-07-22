//
//  ContentView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var alleSnippets: [Snippet]

    @State private var sidebarAuswahl: SidebarItem? = .alle
    @State private var selectedSnippet: Snippet?
    @State private var addSnippetAnzeigen = false
    @State private var tagFilter: String? = nil

    var body: some View {
        NavigationSplitView {
            SidebarView(auswahl: $sidebarAuswahl)
        } content: {
            SnippetListView(
                sidebarItem: sidebarAuswahl ?? .alle,
                selectedSnippet: $selectedSnippet,
                addSnippetAnzeigen: $addSnippetAnzeigen,
                tagFilter: $tagFilter
            )
        } detail: {
            if let snippet = selectedSnippet {
                SnippetDetailView(snippet: snippet, tagFilter: $tagFilter)
            } else {
                ContentUnavailableView(
                    "Kein Snippet ausgewählt",
                    systemImage: "curlybraces",
                    description: Text("Wähle ein Snippet aus der Liste oder erstelle ein neues mit ⌘N.")
                )
            }
        }
        .sheet(isPresented: $addSnippetAnzeigen) {
            AddSnippetView()
        }
        .onChange(of: alleSnippets) { _, snippets in
            SpotlightManager.indexAll(snippets)
        }
        .onAppear {
            SpotlightManager.indexAll(alleSnippets)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Snippet.self, inMemory: true)
}
