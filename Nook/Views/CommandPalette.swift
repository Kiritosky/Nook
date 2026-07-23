//
//  CommandPalette.swift
//  Nook
//
//  Phase 2 – Feature 1+2: Befehls-Palette (⌘K) mit Volltext-Fuzzy-Suche über
//  den Code und kombinierten Filtern. Alles per Tastatur: springen, filtern,
//  kopieren, neu anlegen.
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - Ergebnis-Typen

/// Ein Eintrag in der Palette – entweder eine Aktion oder ein Snippet-Treffer.
private enum PaletteEintrag: Identifiable {
    case aktion(PaletteAktion)
    case snippet(Snippet, trefferZeile: String?)

    var id: String {
        switch self {
        case .aktion(let a):        return "aktion-\(a.id)"
        case .snippet(let s, _):    return "snippet-\(s.persistentModelID.hashValue)"
        }
    }
}

private struct PaletteAktion: Identifiable {
    let id: String
    let titel: LocalizedStringKey
    let symbol: String
    let ausführen: () -> Void
}

// MARK: - CommandPalette

struct CommandPalette: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Snippet> { $0.deletedAt == nil },
           sort: \Snippet.lastAccessedAt, order: .reverse)
    private var snippets: [Snippet]

    /// Wird mit dem gewählten Snippet aufgerufen (Detail öffnen).
    let onSnippetWählen: (Snippet) -> Void
    /// „Neues Snippet"-Aktion.
    let onNeuesSnippet: () -> Void

    @State private var query = ""
    @State private var auswahl = 0
    @State private var kopiertID: PersistentIdentifier?
    @FocusState private var suchfeldFokus: Bool

    // Maximal so viele Snippet-Treffer anzeigen (Palette bleibt schnell & knapp).
    private let maxTreffer = 40

    var body: some View {
        VStack(spacing: 0) {
            suchkopf
            Divider()

            if eintraege.isEmpty {
                leer
            } else {
                liste
            }

            Divider()
            fußzeile
        }
        .frame(width: 620, height: 460)
        .background(.regularMaterial)
        .onAppear { suchfeldFokus = true }
        .onChange(of: query) { _, _ in auswahl = 0 }
    }

    // MARK: Kopf (Suchfeld)

    private var suchkopf: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            TextField("Suchen … (Code, Titel, #tag, lang:swift, projekt:App)", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($suchfeldFokus)
                .onKeyPress(.downArrow) { bewege(1); return .handled }
                .onKeyPress(.upArrow)   { bewege(-1); return .handled }
                .onKeyPress(.escape)    { dismiss(); return .handled }
                .onKeyPress(keys: [.return]) { press in
                    if press.modifiers.contains(.command) { kopiereAktuelles() }
                    else { aktiviereAuswahl() }
                    return .handled
                }
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Liste

    private var liste: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(eintraege.enumerated()), id: \.element.id) { index, eintrag in
                        zeile(eintrag, aktiv: index == auswahl)
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture { auswahl = index; aktiviereAuswahl() }
                    }
                }
                .padding(8)
            }
            .onChange(of: auswahl) { _, neu in
                withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(neu, anchor: .center) }
            }
        }
    }

    @ViewBuilder
    private func zeile(_ eintrag: PaletteEintrag, aktiv: Bool) -> some View {
        HStack(spacing: 11) {
            switch eintrag {
            case .aktion(let a):
                Image(systemName: a.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 26, height: 26)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                Text(a.titel).fontWeight(.medium)
                Spacer()

            case .snippet(let s, let trefferZeile):
                FarbIcon(symbol: s.language.symbolName, farbe: s.akzentFarbe, groesse: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.title.isEmpty ? "Ohne Titel" : s.title)
                        .fontWeight(.medium).lineLimit(1)
                    HStack(spacing: 5) {
                        Text(s.effectiveLanguageName)
                        if let p = s.project, !p.isEmpty {
                            Text("·").foregroundStyle(.quaternary)
                            Text(p).lineLimit(1)
                        }
                        if let tz = trefferZeile {
                            Text("·").foregroundStyle(.quaternary)
                            Text(tz)
                                .fontDesign(.monospaced)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                if kopiertID == s.persistentModelID {
                    Label("Kopiert", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                }
                if s.isFavorite {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(aktiv ? Color.accentColor.opacity(0.18) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8))
    }

    private var leer: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.quaternary)
            Text(query.isEmpty ? "Tippe, um zu suchen" : "Keine Treffer für „\(query)\"")
                .font(.callout).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Fußzeile (Tastatur-Hinweise)

    private var fußzeile: some View {
        HStack(spacing: 14) {
            hinweis("↑↓", "Navigieren")
            hinweis("↩", "Öffnen")
            hinweis("⌘↩", "Kopieren")
            hinweis("esc", "Schließen")
            Spacer()
            Text("\(trefferAnzahl) Treffer")
                .font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    private func hinweis(_ taste: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Text(taste)
                .font(.system(.caption2, design: .monospaced))
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
            Text(text).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Ergebnisberechnung

    private var trefferAnzahl: Int {
        eintraege.filter { if case .snippet = $0 { return true } else { return false } }.count
    }

    /// Kombinierte Liste aus Aktionen (oben) + gerankten Snippet-Treffern.
    private var eintraege: [PaletteEintrag] {
        var result: [PaletteEintrag] = []

        let (filter, freitext) = SucheParser.parse(query)

        // Snippets filtern + ranken
        let getroffen: [(Snippet, Int, String?)] = snippets.compactMap { s in
            guard filter.passt(s) else { return nil }
            if freitext.isEmpty {
                return (s, 0, nil)
            }
            guard let (score, zeile) = SucheParser.bewerte(s, freitext: freitext) else { return nil }
            return (s, score, zeile)
        }

        let sortiert = getroffen.sorted { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            // Bei Gleichstand: zuletzt genutzt zuerst
            return (a.0.lastAccessedAt ?? a.0.createdAt) > (b.0.lastAccessedAt ?? b.0.createdAt)
        }

        // Aktion „Neues Snippet" nur zeigen, wenn kein reiner Filter aktiv ist
        // (bzw. immer als erste Option) – hilft beim schnellen Anlegen.
        result.append(.aktion(PaletteAktion(
            id: "neu",
            titel: query.isEmpty ? "Neues Snippet erstellen" : "Neues Snippet: \(freitext)",
            symbol: "plus.circle.fill",
            ausführen: { onNeuesSnippet() }
        )))

        for (s, _, zeile) in sortiert.prefix(maxTreffer) {
            result.append(.snippet(s, trefferZeile: zeile))
        }
        return result
    }

    // MARK: - Navigation & Aktionen

    private func bewege(_ delta: Int) {
        guard !eintraege.isEmpty else { return }
        auswahl = min(max(auswahl + delta, 0), eintraege.count - 1)
    }

    private func aktiviereAuswahl() {
        guard eintraege.indices.contains(auswahl) else { return }
        switch eintraege[auswahl] {
        case .aktion(let a):
            a.ausführen()
            dismiss()
        case .snippet(let s, _):
            onSnippetWählen(s)
            dismiss()
        }
    }

    private func kopiereAktuelles() {
        guard eintraege.indices.contains(auswahl),
              case let .snippet(s, _) = eintraege[auswahl] else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s.code, forType: .string)
        s.copyCount += 1
        kopiertID = s.persistentModelID
        Task { try? await Task.sleep(for: .seconds(1)); kopiertID = nil }
    }
}
