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
    case sql        = "SQL"
    case html       = "HTML"
    case css        = "CSS"
    case bash       = "Bash"
    case other      = "Sonstiges"

    var symbolName: String {
        switch self {
        case .python:     return "doc.text"
        case .javascript: return "bolt"
        case .swift:      return "swift"
        case .sql:        return "cylinder"
        case .html:       return "globe"
        case .css:        return "paintbrush"
        case .bash:       return "terminal"
        case .other:      return "doc"
        }
    }

    var highlightName: String {
        switch self {
        case .python:     return "python"
        case .javascript: return "javascript"
        case .swift:      return "swift"
        case .sql:        return "sql"
        case .html:       return "xml"
        case .css:        return "css"
        case .bash:       return "bash"
        case .other:      return "plaintext"
        }
    }

    var farbe: Color {
        switch self {
        case .python:     return Color(hex: "3776AB")
        case .javascript: return Color(hex: "F7DF1E")
        case .swift:      return Color(hex: "F05138")
        case .sql:        return Color(hex: "336791")
        case .html:       return Color(hex: "E34F26")
        case .css:        return Color(hex: "1572B6")
        case .bash:       return Color(hex: "4EAA25")
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

    // Benutzerdefinierte Sprache (überschreibt language wenn gesetzt)
    var languageOverride: String?
    var customHighlightName: String?

    var effectiveLanguageName: String {
        languageOverride ?? language.rawValue
    }

    var effectiveHighlightName: String {
        customHighlightName ?? language.highlightName
    }

    // Akzentfarbe: built-in Sprache oder Indigo für eigene
    var akzentFarbe: Color {
        languageOverride != nil ? .indigo : language.farbe
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
        self.languageOverride = languageOverride
        self.customHighlightName = customHighlightName
    }
}
