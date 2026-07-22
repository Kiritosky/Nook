//
//  ContentView.swift
//  Nook
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var alleSnippets: [Snippet]

    @State private var sidebarAuswahl: SidebarItem? = .alle
    @State private var selectedSnippet: Snippet?
    @State private var addSnippetAnzeigen = false
    @State private var tagFilter: String? = nil
    @State private var dropHighlight = false

    // Clipboard-to-Snippet: MenuBar schreibt hier rein
    @AppStorage("pendingClipboardCode") private var pendingClipboardCode: String = ""

    // Auto-Theme-Umschaltung
    @AppStorage("syntaxTheme")       private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("autoTheme")         private var autoTheme: Bool = false
    @AppStorage("autoThemeDark")     private var autoThemeDark: SyntaxTheme = .catppuccinMocha
    @AppStorage("autoThemeLight")    private var autoThemeLight: SyntaxTheme = .xcodeLight

    // Drag-to-create: Datei gedroppt
    @State private var dropInitialCode: String = ""
    @State private var dropInitialLang: Language = .python
    @State private var dropInitialTitle: String = ""

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
                dropZoneHinweis
            }
        }
        .overlay(alignment: .center) {
            if dropHighlight {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .background(Color.accentColor.opacity(0.08).clipShape(RoundedRectangle(cornerRadius: 16)))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        // Datei-Drop → neues Snippet
        .onDrop(of: [.fileURL], isTargeted: $dropHighlight) { providers in
            verarbeiteDroppedFiles(providers)
            return true
        }
        .sheet(isPresented: $addSnippetAnzeigen, onDismiss: {
            pendingClipboardCode = ""
            dropInitialCode = ""
            dropInitialTitle = ""
        }) {
            AddSnippetView(
                initialCode: dropInitialCode.isEmpty ? pendingClipboardCode : dropInitialCode,
                initialLanguage: dropInitialCode.isEmpty ? .python : dropInitialLang,
                initialTitle: dropInitialTitle
            )
        }
        .onChange(of: pendingClipboardCode) { _, new in
            if !new.isEmpty { addSnippetAnzeigen = true }
        }
        .onChange(of: alleSnippets) { _, snippets in
            SpotlightManager.indexAll(snippets)
        }
        // Auto-Theme: folgt Dark/Light-Mode des Systems
        .onChange(of: colorScheme) { _, scheme in
            guard autoTheme else { return }
            syntaxTheme = scheme == .dark ? autoThemeDark : autoThemeLight
        }
        .onAppear {
            SpotlightManager.indexAll(alleSnippets)
            if autoTheme {
                syntaxTheme = colorScheme == .dark ? autoThemeDark : autoThemeLight
            }
            guard !pendingClipboardCode.isEmpty else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                addSnippetAnzeigen = true
            }
        }
    }

    // MARK: - Drop-Zone Placeholder

    private var dropZoneHinweis: some View {
        ContentUnavailableView(
            "Kein Snippet ausgewählt",
            systemImage: "curlybraces",
            description: Text("Wähle ein Snippet aus der Liste oder erstelle eines mit ⌘N.\nCode-Dateien kannst du auch direkt hierher ziehen.")
        )
    }

    // MARK: - Drag & Drop Handler

    private func verarbeiteDroppedFiles(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
                let ext = url.pathExtension
                let lang = Language.fromExtension(ext)
                let title = url.deletingPathExtension().lastPathComponent

                DispatchQueue.main.async {
                    dropInitialCode  = content
                    dropInitialLang  = lang
                    dropInitialTitle = title
                    addSnippetAnzeigen = true
                }
            }
        }
    }
}

// MARK: - Language Extension-Erkennung

extension Language {
    static func fromExtension(_ ext: String) -> Language {
        switch ext.lowercased() {
        case "py":                   return .python
        case "swift":                return .swift
        case "js", "mjs", "cjs":    return .javascript
        case "ts", "mts":            return .typescript
        case "jsx", "tsx":           return .react
        case "vue":                  return .vue
        case "kt", "kts":            return .kotlin
        case "java":                 return .java
        case "c", "h":               return .c
        case "cpp", "cxx", "cc", "hpp": return .cpp
        case "cs":                   return .csharp
        case "rb":                   return .ruby
        case "php":                  return .php
        case "go":                   return .go
        case "rs":                   return .rust
        case "dart":                 return .dart
        case "sql":                  return .sql
        case "json":                 return .json
        case "yaml", "yml":          return .yaml
        case "sh", "bash", "zsh", "fish": return .bash
        case "md", "markdown":       return .markdown
        case "html", "htm":          return .html
        case "css", "scss", "less":  return .css
        default:                     return .other
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Snippet.self, inMemory: true)
}
