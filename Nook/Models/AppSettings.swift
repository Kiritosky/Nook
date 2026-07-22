//
//  AppSettings.swift
//  Nook
//

import SwiftUI

enum SyntaxTheme: String, CaseIterable, Identifiable {
    case catppuccinMocha = "Catppuccin Mocha"
    case nord            = "Nord"
    case githubDark      = "GitHub Dark"
    case oneDark         = "One Dark"
    case monokai         = "Monokai"
    case tokyoNight      = "Tokyo Night"

    var id: String { rawValue }

    var hintergrundHex: String {
        switch self {
        case .catppuccinMocha: return "1e1e2e"
        case .nord:            return "2e3440"
        case .githubDark:      return "0d1117"
        case .oneDark:         return "282c34"
        case .monokai:         return "272822"
        case .tokyoNight:      return "1a1b26"
        }
    }

    var hintergrundFarbe: Color { Color(hex: hintergrundHex) }
}
