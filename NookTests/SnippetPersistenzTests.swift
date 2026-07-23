//
//  SnippetPersistenzTests.swift
//  NookTests
//
//  Sichert die datenkritischen Pfade ab: Export→Import bewahrt alle Felder,
//  der Papierkorb-Status übersteht das Backup, und erneuter Import legt keine
//  Duplikate an. Genau das, worauf sich das automatische Backup verlässt.
//

import Testing
import Foundation
import SwiftData
@testable import Nook

@MainActor
struct SnippetPersistenzTests {

    /// Frischer, rein flüchtiger SwiftData-Container pro Test.
    private func macheContext() throws -> ModelContext {
        let schema = Schema([Snippet.self, CustomLanguage.self, Projekt.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Export → Import bewahrt alle Felder (Roundtrip)")
    func roundtripBewahrtFelder() throws {
        let quelle = Snippet(
            title: "Quicksort", code: "def q(): pass",
            language: .python, topic: "Algorithmen", project: "Studium",
            difficulty: 3, tags: ["sortier", "rekursion"],
            descriptionText: "Teile und herrsche", output: "[1, 2, 3]",
            isFavorite: true, isPinned: true
        )
        quelle.copyCount = 7

        let data = try SnippetImportExport.exportieren([quelle])

        let ctx = try macheContext()
        let ergebnis = try SnippetImportExport.importieren(data, context: ctx, vorhandene: [])
        #expect(ergebnis.neu == 1)
        #expect(ergebnis.uebersprungen == 0)

        let alle = try ctx.fetch(FetchDescriptor<Snippet>())
        #expect(alle.count == 1)
        let s = try #require(alle.first)
        #expect(s.title == "Quicksort")
        #expect(s.code == "def q(): pass")
        #expect(s.language == .python)
        #expect(s.topic == "Algorithmen")
        #expect(s.project == "Studium")
        #expect(s.difficulty == 3)
        #expect(s.tags == ["sortier", "rekursion"])
        #expect(s.descriptionText == "Teile und herrsche")
        #expect(s.output == "[1, 2, 3]")
        #expect(s.isFavorite)
        #expect(s.isPinned)
        #expect(s.copyCount == 7)
    }

    @Test("Papierkorb-Status übersteht den Backup-Roundtrip")
    func papierkorbUeberstehtRoundtrip() throws {
        let geloescht = Snippet(title: "Weg", code: "x", language: .swift)
        geloescht.deletedAt = Date(timeIntervalSince1970: 1_000_000)

        let data = try SnippetImportExport.exportieren([geloescht])
        let ctx = try macheContext()
        try SnippetImportExport.importieren(data, context: ctx, vorhandene: [])

        let s = try #require(try ctx.fetch(FetchDescriptor<Snippet>()).first)
        #expect(s.deletedAt != nil)
        #expect(s.imPapierkorb)
    }

    @Test("Erneuter Import legt keine Duplikate an")
    func erneuterImportKeineDuplikate() throws {
        let a = Snippet(title: "A", code: "1", language: .python)
        let b = Snippet(title: "B", code: "2", language: .swift)
        let data = try SnippetImportExport.exportieren([a, b])

        let ctx = try macheContext()
        let erste = try SnippetImportExport.importieren(data, context: ctx, vorhandene: [])
        #expect(erste.neu == 2)

        let vorhandene = try ctx.fetch(FetchDescriptor<Snippet>())
        let zweite = try SnippetImportExport.importieren(data, context: ctx, vorhandene: vorhandene)
        #expect(zweite.neu == 0)
        #expect(zweite.uebersprungen == 2)
        #expect(try ctx.fetchCount(FetchDescriptor<Snippet>()) == 2)
    }
}
