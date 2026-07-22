//
//  Projekt.swift
//  Nook
//

import Foundation
import SwiftUI
import SwiftData

@Model
class Projekt {
    var name: String
    var symbolName: String
    var colorHex: String
    var createdAt: Date

    var farbe: Color { Color(hex: colorHex) }

    init(name: String = "", symbolName: String = "folder.fill", colorHex: String = "5856D6") {
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}
