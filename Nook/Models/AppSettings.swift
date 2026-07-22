//
//  AppSettings.swift
//  Nook
//

import SwiftUI

// Syntax-Highlighting-Themes (Highlight.js CDN)
enum SyntaxTheme: String, CaseIterable, Identifiable {
    case catppuccinMocha = "Catppuccin Mocha"
    case nord            = "Nord"
    case githubDark      = "GitHub Dark"
    case oneDark         = "One Dark"
    case monokai         = "Monokai"
    case tokyoNight      = "Tokyo Night"

    var id: String { rawValue }

    var cdnSlug: String {
        switch self {
        case .catppuccinMocha: return "base16/catppuccin-mocha"
        case .nord:            return "base16/nord"
        case .githubDark:      return "github-dark"
        case .oneDark:         return "atom-one-dark"
        case .monokai:         return "monokai"
        case .tokyoNight:      return "tokyo-night-dark"
        }
    }

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

    // Lokaler Dateiname im App-Bundle (nach Download)
    var bundleCSS: String {
        switch self {
        case .catppuccinMocha: return "hl-catppuccin-mocha.min.css"
        case .nord:            return "hl-nord.min.css"
        case .githubDark:      return "hl-github-dark.min.css"
        case .oneDark:         return "hl-one-dark.min.css"
        case .monokai:         return "hl-monokai.min.css"
        case .tokyoNight:      return "hl-tokyo-night-dark.min.css"
        }
    }
}
