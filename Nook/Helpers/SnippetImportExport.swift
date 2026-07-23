//
//  SnippetImportExport.swift
//  Nook
//
//  JSON-Export/-Import der Snippet-Sammlung (Datensicherung & Portabilität).
//

import Foundation
import SwiftData

// MARK: - Transportmodell (Codable, entkoppelt vom @Model)

struct SnippetDTO: Codable {
    var title: String
    var code: String
    var language: String
    var topic: String
    var project: String?
    var difficulty: Int
    var tags: [String]
    var descriptionText: String?
    var output: String?
    var createdAt: Date
    var isFavorite: Bool
    var isPinned: Bool
    var languageOverride: String?
    var customHighlightName: String?

    // Ab Schema 1 optional angehängt, damit ein automatisches Backup ein
    // vollständiger Schnappschuss ist. Ältere Dateien ohne diese Felder bleiben
    // lesbar (nil → Standardwert).
    var deletedAt: Date?
    var lastAccessedAt: Date?
    var copyCount: Int?

    @MainActor
    init(_ s: Snippet) {
        title = s.title; code = s.code; language = s.language.rawValue
        topic = s.topic; project = s.project; difficulty = s.difficulty
        tags = s.tags; descriptionText = s.descriptionText; output = s.output
        createdAt = s.createdAt; isFavorite = s.isFavorite; isPinned = s.isPinned
        languageOverride = s.languageOverride; customHighlightName = s.customHighlightName
        deletedAt = s.deletedAt; lastAccessedAt = s.lastAccessedAt; copyCount = s.copyCount
    }

    @MainActor
    func macheSnippet() -> Snippet {
        let snippet = Snippet(
            title: title, code: code,
            language: Language(rawValue: language) ?? .other,
            topic: topic, project: project, difficulty: difficulty,
            tags: tags, descriptionText: descriptionText, output: output,
            isFavorite: isFavorite, isPinned: isPinned,
            languageOverride: languageOverride, customHighlightName: customHighlightName,
            deletedAt: deletedAt
        )
        snippet.createdAt = createdAt
        snippet.lastAccessedAt = lastAccessedAt
        snippet.copyCount = copyCount ?? 0
        return snippet
    }
}

struct NookExport: Codable {
    var schema: Int
    var exportiertAm: Date
    var snippets: [SnippetDTO]
}

// MARK: - Import/Export

@MainActor
enum SnippetImportExport {
    static let dateiendung = "nookbackup"
    static let aktuellesSchema = 1

    /// Kodiert Snippets als hübsches JSON.
    static func exportieren(_ snippets: [Snippet]) throws -> Data {
        let export = NookExport(
            schema: aktuellesSchema,
            exportiertAm: Date(),
            snippets: snippets.map(SnippetDTO.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    /// Liest ein Backup und fügt neue Snippets ein. Duplikate (gleicher Titel +
    /// Code + Erstellzeit) werden übersprungen, damit erneutes Importieren nichts
    /// doppelt anlegt.
    /// - Returns: (neu eingefügt, übersprungen)
    @discardableResult
    static func importieren(_ data: Data, context: ModelContext, vorhandene: [Snippet]) throws -> (neu: Int, uebersprungen: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(NookExport.self, from: data)

        var vorhandeneSchluessel = Set(vorhandene.map(schluessel))
        var neu = 0, uebersprungen = 0

        for dto in export.snippets {
            let key = "\(dto.title)\u{1}\(dto.code)\u{1}\(dto.createdAt.timeIntervalSince1970)"
            if vorhandeneSchluessel.contains(key) { uebersprungen += 1; continue }
            let snippet = dto.macheSnippet()
            context.insert(snippet)
            SpotlightManager.index(snippet)
            vorhandeneSchluessel.insert(key)
            neu += 1
        }
        return (neu, uebersprungen)
    }

    private static func schluessel(_ s: Snippet) -> String {
        "\(s.title)\u{1}\(s.code)\u{1}\(s.createdAt.timeIntervalSince1970)"
    }
}
