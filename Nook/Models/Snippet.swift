//
//  Snippet.swift
//  Nook
//

import Foundation
import SwiftUI
import SwiftData

enum Language: String, CaseIterable, Codable {
    case python     = "Python"
    case javascript = "JavaScript"
    case swift      = "Swift"
    case typescript = "TypeScript"
    case sql        = "SQL"
    case html       = "HTML"
    case css        = "CSS"
    case bash       = "Bash"
    case rust       = "Rust"
    case go         = "Go"
    case other      = "Sonstiges"

    var symbolName: String {
        switch self {
        case .python:     return "doc.text"
        case .javascript: return "bolt"
        case .swift:      return "swift"
        case .typescript: return "t.square"
        case .sql:        return "cylinder"
        case .html:       return "globe"
        case .css:        return "paintbrush"
        case .bash:       return "terminal"
        case .rust:       return "gearshape.2"
        case .go:         return "hare"
        case .other:      return "doc"
        }
    }

    var highlightName: String {
        switch self {
        case .python:     return "python"
        case .javascript: return "javascript"
        case .swift:      return "swift"
        case .typescript: return "typescript"
        case .sql:        return "sql"
        case .html:       return "xml"
        case .css:        return "css"
        case .bash:       return "bash"
        case .rust:       return "rust"
        case .go:         return "go"
        case .other:      return "plaintext"
        }
    }

    var farbe: Color {
        switch self {
        case .python:     return Color(hex: "3776AB")
        case .javascript: return Color(hex: "F7DF1E")
        case .swift:      return Color(hex: "F05138")
        case .typescript: return Color(hex: "3178C6")
        case .sql:        return Color(hex: "336791")
        case .html:       return Color(hex: "E34F26")
        case .css:        return Color(hex: "1572B6")
        case .bash:       return Color(hex: "4EAA25")
        case .rust:       return Color(hex: "CE422B")
        case .go:         return Color(hex: "00ACD7")
        case .other:      return Color(hex: "6C7086")
        }
    }
}

@Model
class Snippet {
    var title: String
    var code: String
    var language: Language
    var topic: String
    var project: String?
    var difficulty: Int
    var tags: [String]
    var descriptionText: String?
    var output: String?
    var createdAt: Date
    var isFavorite: Bool
    var isPinned: Bool
    var lastAccessedAt: Date?

    // Benutzerdefinierte Sprache (überschreibt language wenn gesetzt)
    var languageOverride: String?
    var customHighlightName: String?

    var effectiveLanguageName: String {
        languageOverride ?? language.rawValue
    }

    var effectiveHighlightName: String {
        customHighlightName ?? language.highlightName
    }

    var akzentFarbe: Color {
        languageOverride != nil ? .indigo : language.farbe
    }

    // Stabiler Bezeichner für Spotlight-Indexierung
    var spotlightIdentifier: String {
        "nook-snippet-\(Int(createdAt.timeIntervalSince1970))"
    }

    init(
        title: String = "",
        code: String = "",
        language: Language = .swift,
        topic: String = "",
        project: String? = nil,
        difficulty: Int = 1,
        tags: [String] = [],
        descriptionText: String? = nil,
        output: String? = nil,
        isFavorite: Bool = false,
        isPinned: Bool = false,
        languageOverride: String? = nil,
        customHighlightName: String? = nil
    ) {
        self.title = title
        self.code = code
        self.language = language
        self.topic = topic
        self.project = project
        self.difficulty = difficulty
        self.tags = tags
        self.descriptionText = descriptionText
        self.output = output
        self.createdAt = Date()
        self.isFavorite = isFavorite
        self.isPinned = isPinned
        self.lastAccessedAt = nil
        self.languageOverride = languageOverride
        self.customHighlightName = customHighlightName
    }
}
