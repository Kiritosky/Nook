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

    // Clipboard-to-Snippet: MenuBar schreibt hier rein, ContentView öffnet den Sheet
    @AppStorage("pendingClipboardCode") private var pendingClipboardCode: String = ""

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
        .sheet(isPresented: $addSnippetAnzeigen, onDismiss: { pendingClipboardCode = "" }) {
            AddSnippetView(initialCode: pendingClipboardCode)
        }
        // MenuBar übergibt Clipboard-Text über AppStorage
        .onChange(of: pendingClipboardCode) { _, new in
            if !new.isEmpty { addSnippetAnzeigen = true }
        }
        .onChange(of: alleSnippets) { _, snippets in
            SpotlightManager.indexAll(snippets)
        }
        .onAppear {
            SpotlightManager.indexAll(alleSnippets)
            // Bestehendes Fenster: onAppear feuert bevor onChange den initial gesetzten
            // AppStorage-Wert erkennt → kurze Verzögerung, dann Sheet öffnen
            guard !pendingClipboardCode.isEmpty else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                addSnippetAnzeigen = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Snippet.self, inMemory: true)
}
