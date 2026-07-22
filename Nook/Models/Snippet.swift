//
//  Snippet.swift
//  Nook
//

import Foundation
import SwiftUI
import SwiftData

enum Language: String, CaseIterable, Codable {
    // --- Web ---
    case html       = "HTML"
    case css        = "CSS"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case react      = "React"
    case vue        = "Vue"

    // --- Backend ---
    case python     = "Python"
    case swift      = "Swift"
    case kotlin     = "Kotlin"
    case java       = "Java"
    case c          = "C"
    case cpp        = "C++"
    case csharp     = "C#"
    case ruby       = "Ruby"
    case php        = "PHP"
    case go         = "Go"
    case rust       = "Rust"
    case dart       = "Dart"

    // --- DB / Daten ---
    case sql        = "SQL"
    case json       = "JSON"
    case yaml       = "YAML"

    // --- Shell / Docs ---
    case bash       = "Bash"
    case markdown   = "Markdown"

    case other      = "Sonstiges"

    var symbolName: String {
        switch self {
        case .html:       return "globe"
        case .css:        return "paintbrush"
        case .javascript: return "bolt"
        case .typescript: return "t.square.fill"
        case .react:      return "atom"
        case .vue:        return "triangle.fill"
        case .python:     return "doc.text"
        case .swift:      return "swift"
        case .kotlin:     return "k.square.fill"
        case .java:       return "cup.and.saucer.fill"
        case .c:          return "c.square.fill"
        case .cpp:        return "plus.diamond.fill"
        case .csharp:     return "number.square.fill"
        case .ruby:       return "diamond.fill"
        case .php:        return "server.rack"
        case .go:         return "hare"
        case .rust:       return "gearshape.2"
        case .dart:       return "scope"
        case .sql:        return "cylinder"
        case .json:       return "curlybraces.square.fill"
        case .yaml:       return "list.bullet.indent"
        case .bash:       return "terminal"
        case .markdown:   return "doc.richtext.fill"
        case .other:      return "doc"
        }
    }

    var highlightName: String {
        switch self {
        case .html:       return "html"
        case .css:        return "css"
        case .javascript: return "javascript"
        case .typescript: return "typescript"
        case .react:      return "jsx"
        case .vue:        return "vue"
        case .python:     return "python"
        case .swift:      return "swift"
        case .kotlin:     return "kotlin"
        case .java:       return "java"
        case .c:          return "c"
        case .cpp:        return "cpp"
        case .csharp:     return "csharp"
        case .ruby:       return "ruby"
        case .php:        return "php"
        case .go:         return "go"
        case .rust:       return "rust"
        case .dart:       return "dart"
        case .sql:        return "sql"
        case .json:       return "json"
        case .yaml:       return "yaml"
        case .bash:       return "bash"
        case .markdown:   return "markdown"
        case .other:      return "plaintext"
        }
    }

    var farbe: Color {
        switch self {
        case .html:       return Color(hex: "E34F26")
        case .css:        return Color(hex: "1572B6")
        case .javascript: return Color(hex: "F7DF1E")
        case .typescript: return Color(hex: "3178C6")
        case .react:      return Color(hex: "61DAFB")
        case .vue:        return Color(hex: "4FC08D")
        case .python:     return Color(hex: "3776AB")
        case .swift:      return Color(hex: "F05138")
        case .kotlin:     return Color(hex: "7F52FF")
        case .java:       return Color(hex: "ED8B00")
        case .c:          return Color(hex: "5B8DC9")
        case .cpp:        return Color(hex: "00599C")
        case .csharp:     return Color(hex: "68217A")
        case .ruby:       return Color(hex: "CC342D")
        case .php:        return Color(hex: "777BB4")
        case .go:         return Color(hex: "00ACD7")
        case .rust:       return Color(hex: "CE422B")
        case .dart:       return Color(hex: "00B4AB")
        case .sql:        return Color(hex: "336791")
        case .json:       return Color(hex: "F5A623")
        case .yaml:       return Color(hex: "CB171E")
        case .bash:       return Color(hex: "4EAA25")
        case .markdown:   return Color(hex: "4A90D9")
        case .other:      return Color(hex: "6C7086")
        }
    }

    // Gruppen für übersichtliche Anzeige im Language-Grid
    static var gruppen: [(titel: String, sprachen: [Language])] {
        [
            ("Web", [.html, .css, .javascript, .typescript, .react, .vue]),
            ("Backend", [.python, .swift, .kotlin, .java, .c, .cpp, .csharp, .ruby, .php, .go, .rust, .dart]),
            ("Daten & Shell", [.sql, .json, .yaml, .bash, .markdown]),
            ("Sonstiges", [.other])
        ]
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

    var languageOverride: String?
    var customHighlightName: String?

    var effectiveLanguageName: String { languageOverride ?? language.rawValue }

    var effectiveHighlightName: String { customHighlightName ?? language.highlightName }

    var akzentFarbe: Color { languageOverride != nil ? .indigo : language.farbe }

    var spotlightIdentifier: String { "nook-snippet-\(Int(createdAt.timeIntervalSince1970))" }

    init(
        title: String = "",
        code: String = "",
        language: Language = .python,
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
