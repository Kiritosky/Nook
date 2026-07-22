//
//  AppSettings.swift
//  Nook
//

import SwiftUI

enum SyntaxTheme: String, CaseIterable, Identifiable {
    // Dunkel
    case catppuccinMocha = "Catppuccin Mocha"
    case nord            = "Nord"
    case githubDark      = "GitHub Dark"
    case oneDark         = "One Dark"
    case monokai         = "Monokai"
    case tokyoNight      = "Tokyo Night"
    // Hell
    case xcodeLight      = "Xcode Light"
    case githubLight     = "GitHub Light"

    var id: String { rawValue }

    var isLight: Bool {
        switch self {
        case .xcodeLight, .githubLight: return true
        default: return false
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
        case .xcodeLight:      return "FFFFFF"
        case .githubLight:     return "FAFBFC"
        }
    }

    var hintergrundFarbe: Color { Color(hex: hintergrundHex) }
}

// MARK: - App-Sprache (Oberfläche)

enum AppSprache: String, CaseIterable, Identifiable {
    case system, deutsch, englisch

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .system:   return "Systemsprache"
        case .deutsch:  return "Deutsch"
        case .englisch: return "English"
        }
    }

    /// Sprachkürzel oder nil für „Systemsprache".
    var code: String? {
        switch self {
        case .system:   return nil
        case .deutsch:  return "de"
        case .englisch: return "en"
        }
    }

    /// Ob die Oberfläche aktuell auf Englisch dargestellt werden soll.
    static var effektivEnglisch: Bool {
        let raw = UserDefaults.standard.string(forKey: "appSprache") ?? "system"
        switch raw {
        case AppSprache.deutsch.rawValue:  return false
        case AppSprache.englisch.rawValue: return true
        default: return (Locale.preferredLanguages.first ?? "de").hasPrefix("en")
        }
    }
}

