//
//  SucheParser.swift
//  Nook
//
//  Phase 2 – Feature 2: Volltext-Fuzzy-Suche über den Code plus kombinierte
//  Filter (Sprache × Projekt × Tag × Status). Wird von der CommandPalette und
//  perspektivisch von der Hauptsuche genutzt.
//

import Foundation

enum SucheParser {

    // MARK: - Filter

    /// Strukturierte Filter aus Tokens wie `lang:swift`, `projekt:App`, `#tag`,
    /// `is:favorit`. Mehrere Werte einer Art wirken als ODER, verschiedene Arten
    /// als UND (Sprache × Projekt × Tag).
    struct Filter {
        var sprachen: [String] = []
        var projekte: [String] = []
        var tags: [String] = []
        var nurFavoriten = false
        var nurAngeheftet = false

        var istLeer: Bool {
            sprachen.isEmpty && projekte.isEmpty && tags.isEmpty
                && !nurFavoriten && !nurAngeheftet
        }

        func passt(_ s: Snippet) -> Bool {
            if nurFavoriten && !s.isFavorite { return false }
            if nurAngeheftet && !s.isPinned { return false }
            if !sprachen.isEmpty {
                let name = s.effectiveLanguageName.lowercased()
                let hl = s.effectiveHighlightName.lowercased()
                guard sprachen.contains(where: { name.contains($0) || hl.contains($0) }) else { return false }
            }
            if !projekte.isEmpty {
                let p = (s.project ?? "").lowercased()
                guard projekte.contains(where: { p.contains($0) }) else { return false }
            }
            if !tags.isEmpty {
                let st = s.tags.map { $0.lowercased() }
                guard tags.allSatisfy({ t in st.contains(where: { $0.contains(t) }) }) else { return false }
            }
            return true
        }
    }

    // MARK: - Parsing

    /// Zerlegt die Eingabe in Filter-Tokens und freien Suchtext.
    static func parse(_ query: String) -> (filter: Filter, freitext: String) {
        var filter = Filter()
        var freiWorte: [String] = []

        for rohToken in query.split(separator: " ") {
            let token = String(rohToken)
            let lower = token.lowercased()

            if lower.hasPrefix("#"), token.count > 1 {
                filter.tags.append(String(lower.dropFirst()))
            } else if lower.hasPrefix("lang:") || lower.hasPrefix("sprache:") {
                filter.sprachen.append(wert(nach: ":", in: lower))
            } else if lower.hasPrefix("projekt:") || lower.hasPrefix("project:") || lower.hasPrefix("proj:") {
                filter.projekte.append(wert(nach: ":", in: lower))
            } else if lower.hasPrefix("tag:") {
                filter.tags.append(wert(nach: ":", in: lower))
            } else if lower == "is:favorit" || lower == "is:favorite" || lower == "is:fav" {
                filter.nurFavoriten = true
            } else if lower == "is:pinned" || lower == "is:angeheftet" || lower == "is:pin" {
                filter.nurAngeheftet = true
            } else {
                freiWorte.append(token)
            }
        }
        // Leere Filterwerte (z. B. „lang:") wieder verwerfen
        filter.sprachen.removeAll { $0.isEmpty }
        filter.projekte.removeAll { $0.isEmpty }
        filter.tags.removeAll { $0.isEmpty }

        return (filter, freiWorte.joined(separator: " "))
    }

    private static func wert(nach trenner: String, in token: String) -> String {
        guard let r = token.range(of: trenner) else { return "" }
        return String(token[r.upperBound...])
    }

    // MARK: - Bewertung (Ranking + Treffer-Zeile)

    /// Bewertet ein Snippet gegen den freien Suchtext. Gibt `nil` zurück, wenn es
    /// nicht passt, sonst (Score, optional gefundene Code-Zeile zur Vorschau).
    static func bewerte(_ s: Snippet, freitext: String) -> (score: Int, trefferZeile: String?)? {
        let q = freitext.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return (0, nil) }

        var score = 0
        var codeZeile: String?

        let titel = s.title.lowercased()
        if titel.contains(q) {
            score += titel.hasPrefix(q) ? 160 : 120
        } else if let f = fuzzyScore(q, titel) {
            score += 60 + f            // Fuzzy-Subsequenz im Titel
        }

        if s.topic.lowercased().contains(q)              { score += 55 }
        if (s.project ?? "").lowercased().contains(q)    { score += 50 }
        if s.effectiveLanguageName.lowercased().contains(q) { score += 45 }
        if s.tags.contains(where: { $0.lowercased().contains(q) }) { score += 45 }
        if (s.descriptionText ?? "").lowercased().contains(q) { score += 30 }

        // Volltext im Code – plus die erste passende Zeile als Vorschau.
        if let zeile = ersteCodeZeile(s.code, enthält: q) {
            score += 35
            codeZeile = zeile
        }

        // Fallback: alle Suchwörter irgendwo (UND) – fängt Mehrwort-Suchen wie
        // „python sort" ab, auch wenn kein Feld die ganze Phrase enthält.
        if score == 0 {
            let worte = q.split(separator: " ").map(String.init)
            if worte.count > 1 {
                let heu = ([s.title, s.topic, s.project ?? "", s.effectiveLanguageName,
                            s.tags.joined(separator: " "), s.descriptionText ?? "", s.code]
                    .joined(separator: " ")).lowercased()
                if worte.allSatisfy({ heu.contains($0) }) {
                    score += 25
                    codeZeile = codeZeile ?? worte.compactMap { ersteCodeZeile(s.code, enthält: $0) }.first
                }
            }
        }

        return score > 0 ? (score, codeZeile) : nil
    }

    /// Erste Zeile des Codes, die den Suchtext enthält – getrimmt & gekürzt.
    private static func ersteCodeZeile(_ code: String, enthält q: String) -> String? {
        for zeile in code.split(separator: "\n") {
            if zeile.lowercased().contains(q) {
                let t = zeile.trimmingCharacters(in: .whitespaces)
                return t.count > 80 ? String(t.prefix(80)) + "…" : t
            }
        }
        return nil
    }

    /// Einfache Fuzzy-Subsequenz: prüft, ob `needle` als Teilfolge in `haystack`
    /// vorkommt, und belohnt zusammenhängende/frühe Treffer.
    static func fuzzyScore(_ needle: String, _ haystack: String) -> Int? {
        guard !needle.isEmpty else { return 0 }
        let n = Array(needle), h = Array(haystack)
        var ni = 0, punkte = 0, letzte = -2
        for (hi, ch) in h.enumerated() {
            if ni < n.count && ch == n[ni] {
                punkte += (hi == letzte + 1) ? 5 : 1   // Bonus für zusammenhängend
                if hi < 6 { punkte += 2 }               // Bonus für frühen Treffer
                letzte = hi
                ni += 1
            }
        }
        return ni == n.count ? punkte : nil
    }
}
