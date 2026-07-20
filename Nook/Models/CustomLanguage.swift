//
//  CustomLanguage.swift
//  Nook
//

import Foundation
import SwiftData

@Model
class CustomLanguage {
    var name: String
    var highlightName: String  // Highlight.js Bezeichner, z.B. "rust", "kotlin"
    var symbolName: String     // SF Symbol

    init(name: String, highlightName: String, symbolName: String = "doc.text") {
        self.name = name
        self.highlightName = highlightName
        self.symbolName = symbolName
    }
}
