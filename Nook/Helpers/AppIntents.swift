//
//  AppIntents.swift
//  Nook
//

import AppIntents
import AppKit
import SwiftData

// MARK: - Snippet-Code abrufen

struct SnippetCodeAbrufenIntent: AppIntent {
    static var title: LocalizedStringResource = "Snippet-Code abrufen"
    static var description: IntentDescription = .init(
        "Gibt den Code eines Nook-Snippets zurück, damit er in anderen Aktionen verwendet werden kann.",
        categoryName: "Nook"
    )

    @Parameter(title: "Snippet-Titel", description: "Titel oder Teil des Titels des Snippets")
    var snippetTitel: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let snippets = try alleSnippets()
        let treffer = snippets.filter { $0.title.localizedCaseInsensitiveContains(snippetTitel) }

        guard let snippet = treffer.first else {
            throw NookIntentFehler.nichtGefunden(snippetTitel)
        }

        return .result(value: snippet.code, dialog: "'\(snippet.title)' zurückgegeben.")
    }
}

// MARK: - Snippet kopieren

struct SnippetKopierenIntent: AppIntent {
    static var title: LocalizedStringResource = "Snippet in Zwischenablage"
    static var description: IntentDescription = .init(
        "Kopiert den Code eines Nook-Snippets in die Zwischenablage.",
        categoryName: "Nook"
    )

    @Parameter(title: "Snippet-Titel")
    var snippetTitel: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snippets = try alleSnippets()
        let treffer = snippets.filter { $0.title.localizedCaseInsensitiveContains(snippetTitel) }

        guard let snippet = treffer.first else {
            throw NookIntentFehler.nichtGefunden(snippetTitel)
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)

        return .result(dialog: "'\(snippet.title)' kopiert.")
    }
}

// MARK: - Snippets auflisten

struct SnippetsAuflistenIntent: AppIntent {
    static var title: LocalizedStringResource = "Snippets auflisten"
    static var description: IntentDescription = .init(
        "Gibt eine Liste aller gespeicherten Snippet-Titel zurück.",
        categoryName: "Nook"
    )

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        let snippets = try alleSnippets()
        let titel = snippets.map { $0.title }
        return .result(value: titel, dialog: "\(titel.count) Snippets gefunden.")
    }
}

// MARK: - Fehler

enum NookIntentFehler: Error, CustomLocalizedStringResourceConvertible {
    case nichtGefunden(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .nichtGefunden(let titel):
            return "Kein Snippet mit dem Titel '\(titel)' gefunden."
        }
    }
}

// MARK: - SwiftData-Hilfsfunktion für Intents

private func alleSnippets() throws -> [Snippet] {
    let schema = Schema([Snippet.self, CustomLanguage.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    let container = try ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)
    return try context.fetch(FetchDescriptor<Snippet>())
}
