//
//  Snippet.swift
//  Nook
//

import Foundation
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

    // Angezeigter Sprachname (built-in oder custom)
    var effectiveLanguageName: String {
        languageOverride ?? language.rawValue
    }

    // Highlight.js Bezeichner
    var effectiveHighlightName: String {
        customHighlightName ?? language.highlightName
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
