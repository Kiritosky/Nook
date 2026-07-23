//
//  SmartSammlung.swift
//  Nook
//
//  Phase 2 – Feature 5: Smart-Sammlungen = gespeicherte Suchen als virtuelle
//  Ordner in der Sidebar. Der `query` nutzt dieselbe Syntax wie die Suche
//  (Freitext + Filter: lang:, projekt:, #tag, is:favorit …) → siehe SucheParser.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class SmartSammlung {
    var name: String
    var query: String
    var symbolName: String
    var colorHex: String
    var createdAt: Date

    init(name: String,
         query: String,
         symbolName: String = "line.3.horizontal.decrease.circle.fill",
         colorHex: String = "5AC8FA") {
        self.name = name
        self.query = query
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.createdAt = Date()
    }

    var farbe: Color { Color(hex: colorHex) }
}
