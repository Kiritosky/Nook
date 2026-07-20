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
}

@Model
class Snippet {
    var title: String
    var code: String
    var language: Language
    var topic: String
    var project: String?
    var difficulty: Int          // 1 = Anfänger, 2 = Mittel, 3 = Fortgeschritten
    var tags: [String]
    var descriptionText: String?
    var output: String?
    var createdAt: Date
    var isFavorite: Bool

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
        isFavorite: Bool = false
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
    }
}
