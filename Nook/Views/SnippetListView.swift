//
//  SnippetListView.swift
//  Nook
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

enum Sortierung: String, CaseIterable {
    case neueste        = "neueste"
    case aelteste       = "aelteste"
    case titel          = "titel"
    case zuleztGeoeffnet = "zuleztGeoeffnet"

    var bezeichnung: String {
        switch self {
        case .neueste:         return "Neueste zuerst"
        case .aelteste:        return "Älteste zuerst"
        case .titel:           return "Nach Titel (A–Z)"
        case .zuleztGeoeffnet: return "Zuletzt geöffnet"
        }
    }

    var symbolName: String {
        switch self {
        case .neueste:         return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .aelteste:        return "clock"
        case .titel:           return "textformat.abc"
        case .zuleztGeoeffnet: return "eye"
        }
    }
}

struct SnippetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PapierkorbManager.self) private var papierkorb
    @Query(filter: #Predicate<Snippet> { $0.deletedAt == nil })
    private var alleSnippets: [Snippet]
    @Query(filter: #Predicate<Snippet> { $0.deletedAt != nil }, sort: \Snippet.deletedAt, order: .reverse)
    private var papierkorbSnippets: [Snippet]
    @Query(sort: \Projekt.name) private var projekte: [Projekt]

    let sidebarItem: SidebarItem
    @Binding var selectedSnippet: Snippet?
    @Binding var addSnippetAnzeigen: Bool
    @Binding var tagFilter: String?
    @Binding var suchtext: String
    @State private var schwierigkeitsFilter: Int? = nil
    @AppStorage("snippetSortierung") private var sortierung: Sortierung = .neueste

    // Massenaktionen (Mehrfachauswahl)
    @State private var auswahlModus = false
    @State private var mehrfachAuswahl: Set<PersistentIdentifier> = []
    @State private var tagPopover = false
    @State private var tagEingabe = ""

    private var ausgewaehlteSnippets: [Snippet] {
        gefilterteSnippets.filter { mehrfachAuswahl.contains($0.persistentModelID) }
    }

    private var istPapierkorb: Bool { if case .papierkorb = sidebarItem { return true } else { return false } }

    /// Tag-Autovervollständigung: nur wenn die Suche mit `#` beginnt, passende Tags
    /// aus dem aktuellen Bestand vorschlagen (alphabetisch, max. 8).
    private var tagVorschlaege: [String] {
        let text = suchtext.trimmingCharacters(in: .whitespaces)
        guard text.hasPrefix("#") else { return [] }
        let begriff = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        let alleTags = Set(alleSnippets.flatMap { $0.tags })
        let passend = begriff.isEmpty
            ? alleTags
            : alleTags.filter { $0.localizedCaseInsensitiveContains(begriff) }
        // Exakte Eingabe nicht nochmal vorschlagen
        return passend
            .filter { $0.caseInsensitiveCompare(begriff) != .orderedSame }
            .sorted()
            .prefix(8)
            .map { $0 }
    }

    private var basisSnippets: [Snippet] {
        // Papierkorb: bereits nach Löschzeitpunkt sortiert, ohne Anheften-Logik
        if case .papierkorb = sidebarItem { return papierkorbSnippets }

        let gefiltert: [Snippet]
        switch sidebarItem {
        case .alle:                    gefiltert = alleSnippets
        case .favoriten:               gefiltert = alleSnippets.filter { $0.isFavorite }
        case .angeheftet:              gefiltert = alleSnippets.filter { $0.isPinned }
        case .sprache(let lang):       gefiltert = alleSnippets.filter { $0.language == lang && $0.languageOverride == nil }
        case .customSprache(let name): gefiltert = alleSnippets.filter { $0.languageOverride == name }
        case .projekt(let proj):       gefiltert = alleSnippets.filter { $0.project == proj }
        case .tag(let tag):            gefiltert = alleSnippets.filter { $0.tags.contains(tag) }
        case .thema(let thema):        gefiltert = alleSnippets.filter { $0.themen.contains(thema) }
        case .papierkorb:              gefiltert = papierkorbSnippets   // via Früh-Return oben abgedeckt
        case .projekteBrowser, .themenBrowser, .tagsBrowser:
            gefiltert = []   // werden nie direkt als Liste gezeigt (siehe ContentView-Browser)
        }

        let sortiert: [Snippet]
        switch sortierung {
        case .neueste:         sortiert = gefiltert.sorted { $0.createdAt > $1.createdAt }
        case .aelteste:        sortiert = gefiltert.sorted { $0.createdAt < $1.createdAt }
        case .titel:           sortiert = gefiltert.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .zuleztGeoeffnet: sortiert = gefiltert.sorted { ($0.lastAccessedAt ?? $0.createdAt) > ($1.lastAccessedAt ?? $1.createdAt) }
        }

        // Angeheftete immer zuerst (außer wenn wir schon nach Angehefteten filtern)
        if case .angeheftet = sidebarItem { return sortiert }
        return sortiert.sorted { $0.isPinned && !$1.isPinned }
    }

    private var gefilterteSnippets: [Snippet] {
        var r = basisSnippets
        if let s = schwierigkeitsFilter { r = r.filter { $0.difficulty == s } }
        if let tag = tagFilter { r = r.filter { $0.tags.contains(tag) } }

        let text = suchtext.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return r }

        // Explizite Tag-Suche: "#tag" filtert ausschließlich nach Tags.
        if text.hasPrefix("#") {
            let begriff = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
            guard !begriff.isEmpty else { return r }
            return r.filter { $0.tags.contains { $0.localizedCaseInsensitiveContains(begriff) } }
        }

        return r.filter {
            $0.title.localizedCaseInsensitiveContains(text) ||
            $0.topic.localizedCaseInsensitiveContains(text) ||
            $0.code.localizedCaseInsensitiveContains(text) ||
            $0.effectiveLanguageName.localizedCaseInsensitiveContains(text) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tag-Filter Banner
            if let tag = tagFilter {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill").font(.caption2).foregroundStyle(.purple)
                    Text("#\(tag)").font(.caption).fontWeight(.semibold).foregroundStyle(.purple)
                    Spacer()
                    Button { tagFilter = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.caption)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Color.purple.opacity(0.08))
                Divider()
            }

            // Filter-Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(label: "Alle",          symbol: "square.grid.2x2",       aktiv: schwierigkeitsFilter == nil) { schwierigkeitsFilter = nil }
                    FilterChip(label: "Anfänger",      symbol: "circle.fill",            aktiv: schwierigkeitsFilter == 1)   { schwierigkeitsFilter = schwierigkeitsFilter == 1 ? nil : 1 }
                    FilterChip(label: "Mittel",        symbol: "circle.lefthalf.filled", aktiv: schwierigkeitsFilter == 2)  { schwierigkeitsFilter = schwierigkeitsFilter == 2 ? nil : 2 }
                    FilterChip(label: "Fortgeschritten", symbol: "record.circle",        aktiv: schwierigkeitsFilter == 3)   { schwierigkeitsFilter = schwierigkeitsFilter == 3 ? nil : 3 }
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
            }
            .background(.bar)

            // Papierkorb-Kopfleiste
            if istPapierkorb {
                HStack(spacing: 8) {
                    Image(systemName: "trash").font(.caption).foregroundStyle(.secondary)
                    Text("Gelöschte Snippets kannst du wiederherstellen oder endgültig entfernen.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if !papierkorbSnippets.isEmpty {
                        Button(role: .destructive) {
                            if let sel = selectedSnippet, sel.imPapierkorb { selectedSnippet = nil }
                            papierkorb.papierkorbLeeren(papierkorbSnippets, context: modelContext)
                        } label: {
                            Text("Papierkorb leeren").font(.caption)
                        }
                        .buttonStyle(.plain).foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(.bar)
                Divider()
            }

            if gefilterteSnippets.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(gefilterteSnippets) { snippet in
                            let markiert = mehrfachAuswahl.contains(snippet.persistentModelID)
                            SnippetKarte(snippet: snippet,
                                         istAusgewaehlt: auswahlModus ? markiert : selectedSnippet == snippet)
                                .overlay(alignment: .topLeading) {
                                    if auswahlModus {
                                        Image(systemName: markiert ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(markiert ? Color.accentColor : Color.secondary.opacity(0.6))
                                            .background(Circle().fill(.background).padding(2))
                                            .padding(6)
                                    }
                                }
                                .onTapGesture {
                                    if auswahlModus { markierungWechseln(snippet) }
                                    else { selectedSnippet = snippet }
                                }
                                .contextMenu {
                                    if snippet.imPapierkorb {
                                        Button { papierkorb.wiederherstellen(snippet) } label: {
                                            Label("Wiederherstellen", systemImage: "arrow.uturn.backward")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            if selectedSnippet == snippet { selectedSnippet = nil }
                                            papierkorb.endgueltigLoeschen(snippet, context: modelContext)
                                        } label: {
                                            Label("Endgültig löschen", systemImage: "trash")
                                        }
                                    } else {
                                        Button { snippet.isPinned.toggle() } label: {
                                            Label(snippet.isPinned ? "Losgelöst" : "Anheften",
                                                  systemImage: snippet.isPinned ? "pin.slash" : "pin")
                                        }
                                        Button { snippet.isFavorite.toggle() } label: {
                                            Label(snippet.isFavorite ? "Aus Favoriten" : "Zu Favoriten",
                                                  systemImage: snippet.isFavorite ? "star.slash" : "star")
                                        }
                                        Button { duplizieren(snippet) } label: {
                                            Label("Duplizieren", systemImage: "doc.on.doc")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            if selectedSnippet == snippet { selectedSnippet = nil }
                                            papierkorb.loeschen(snippet)
                                        } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 10)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if auswahlModus {
                massenAktionsLeiste
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .searchable(text: $suchtext, prompt: Text("Suchen… (#tag für Tags)"))
        .searchSuggestions {
            ForEach(tagVorschlaege, id: \.self) { tag in
                Label("#\(tag)", systemImage: "number")
                    .searchCompletion("#\(tag)")
            }
        }
        .navigationTitle(LocalizedStringKey(titelFuerAuswahl))
        .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { addSnippetAnzeigen = true } label: {
                    Label("Hinzufügen", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            if !istPapierkorb && !gefilterteSnippets.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            auswahlModus.toggle()
                            if !auswahlModus { mehrfachAuswahl.removeAll() }
                        }
                    } label: {
                        Label(auswahlModus ? "Fertig" : "Auswählen",
                              systemImage: auswahlModus ? "checkmark.circle" : "checkmark.circle.badge.questionmark")
                    }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Sortierung", selection: $sortierung) {
                        ForEach(Sortierung.allCases, id: \.self) { s in
                            Label(s.bezeichnung, systemImage: s.symbolName).tag(s)
                        }
                    }
                } label: {
                    Label("Sortierung", systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }

    private var titelFuerAuswahl: String {
        switch sidebarItem {
        case .alle:                    return "Alle Snippets"
        case .favoriten:               return "Favoriten"
        case .angeheftet:              return "Angeheftet"
        case .sprache(let lang):       return lang.rawValue
        case .customSprache(let name): return name
        case .projekt(let proj):       return proj
        case .tag(let tag):            return "#\(tag)"
        case .thema(let thema):        return thema
        case .papierkorb:              return "Papierkorb"
        case .projekteBrowser:         return "Projekte"
        case .themenBrowser:           return "Themen"
        case .tagsBrowser:             return "Tags"
        }
    }

    private var emptyState: some View {
        let istLeer      = alleSnippets.isEmpty
        let istTagFilter = tagFilter != nil
        let istSuche     = !suchtext.isEmpty

        return VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.08)).frame(width: 68, height: 68)
                Image(systemName: istTagFilter ? "tag.slash" : istSuche ? "magnifyingglass" : "curlybraces")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Color.accentColor.opacity(0.6))
                    .symbolEffect(.pulse, isActive: istSuche)
            }
            VStack(spacing: 5) {
                Text(istTagFilter ? "Kein Snippet mit diesem Tag"
                     : istSuche ? "Keine Treffer" : "Noch keine Snippets")
                    .font(.headline)
                Text(istTagFilter ? "Tag-Filter aufheben um alle zu sehen."
                     : istSuche ? "Versuche einen anderen Begriff."
                     : "Erstelle dein erstes Snippet und leg los.")
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if istLeer && !istSuche && !istTagFilter {
                Button { addSnippetAnzeigen = true } label: {
                    Label("Erstes Snippet erstellen", systemImage: "plus")
                        .font(.callout).fontWeight(.medium)
                }.buttonStyle(.borderedProminent).controlSize(.large)
            } else if istTagFilter {
                Button("Filter aufheben") { tagFilter = nil }.buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    // MARK: - Massenaktionen

    private var massenAktionsLeiste: some View {
        let anzahl = mehrfachAuswahl.count
        let alleMarkiert = anzahl == gefilterteSnippets.count && anzahl > 0
        return HStack(spacing: 10) {
            Button(alleMarkiert ? "Keine" : "Alle") {
                if alleMarkiert { mehrfachAuswahl.removeAll() }
                else { mehrfachAuswahl = Set(gefilterteSnippets.map { $0.persistentModelID }) }
            }
            .buttonStyle(.plain).font(.caption).fontWeight(.medium)
            .foregroundStyle(Color.accentColor)

            Text("\(anzahl) ausgewählt")
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()

            Spacer()

            if anzahl > 0 {
                aktionsButton("star", "Favorit setzen") { favoritSetzen(true) }
                aktionsButton("pin", "Anheften") { anheften(true) }

                Menu {
                    Button("Kein Projekt") { projektZuweisen(nil) }
                    if !projekte.isEmpty { Divider() }
                    ForEach(projekte) { p in
                        Button { projektZuweisen(p.name) } label: {
                            Label(p.name, systemImage: p.symbolName)
                        }
                    }
                } label: {
                    Image(systemName: "folder").font(.system(size: 14))
                }
                .menuStyle(.borderlessButton).fixedSize().help("Projekt zuweisen")

                aktionsButton("number", "Tag hinzufügen") { tagEingabe = ""; tagPopover = true }
                    .popover(isPresented: $tagPopover, arrowEdge: .top) { tagPopoverInhalt }

                aktionsButton("square.and.arrow.up", "Auswahl exportieren") { exportierenAuswahl() }
                aktionsButton("trash", "In den Papierkorb", rot: true) { loeschenAuswahl() }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func aktionsButton(_ symbol: String, _ hilfe: String,
                               rot: Bool = false, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(rot ? Color.red : Color.primary)
                .frame(width: 30, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).help(hilfe)
    }

    private var tagPopoverInhalt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tag zu \(mehrfachAuswahl.count) Snippets hinzufügen")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                TextField("Tag-Name", text: $tagEingabe)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                    .onSubmit { tagHinzufuegen() }
                Button("Hinzufügen") { tagHinzufuegen() }
                    .buttonStyle(.borderedProminent)
                    .disabled(tagEingabe.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(14)
    }

    private func markierungWechseln(_ s: Snippet) {
        if mehrfachAuswahl.contains(s.persistentModelID) {
            mehrfachAuswahl.remove(s.persistentModelID)
        } else {
            mehrfachAuswahl.insert(s.persistentModelID)
        }
    }

    private func favoritSetzen(_ wert: Bool) {
        // Umschalten: wenn alle schon Favorit sind, entfernen – sonst setzen.
        let alleFavorit = ausgewaehlteSnippets.allSatisfy { $0.isFavorite }
        for s in ausgewaehlteSnippets { s.isFavorite = !alleFavorit }
    }

    private func anheften(_ wert: Bool) {
        let alleGepinnt = ausgewaehlteSnippets.allSatisfy { $0.isPinned }
        for s in ausgewaehlteSnippets { s.isPinned = !alleGepinnt }
    }

    private func projektZuweisen(_ name: String?) {
        for s in ausgewaehlteSnippets { s.project = name }
    }

    private func tagHinzufuegen() {
        let tag = tagEingabe.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty else { return }
        for s in ausgewaehlteSnippets where !s.tags.contains(tag) {
            s.tags.append(tag)
        }
        tagEingabe = ""
        tagPopover = false
    }

    private func loeschenAuswahl() {
        let ziele = ausgewaehlteSnippets
        if let sel = selectedSnippet, ziele.contains(sel) { selectedSnippet = nil }
        for s in ziele { papierkorb.loeschen(s) }
        mehrfachAuswahl.removeAll()
        withAnimation(.easeInOut(duration: 0.2)) { auswahlModus = false }
    }

    private func exportierenAuswahl() {
        let ziele = ausgewaehlteSnippets
        guard !ziele.isEmpty else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Nook-Auswahl-\(ziele.count).json"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let data = try? SnippetImportExport.exportieren(ziele) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func duplizieren(_ original: Snippet) {
        let kopie = Snippet(
            title: "\(original.title) (Kopie)",
            code: original.code, language: original.language,
            topic: original.topic, project: original.project,
            difficulty: original.difficulty, tags: original.tags,
            descriptionText: original.descriptionText, output: original.output,
            languageOverride: original.languageOverride,
            customHighlightName: original.customHighlightName
        )
        modelContext.insert(kopie)
        SpotlightManager.index(kopie)
        selectedSnippet = kopie
    }
}

// MARK: - Snippet-Karte

struct SnippetKarte: View {
    let snippet: Snippet
    let istAusgewaehlt: Bool

    @AppStorage("showCodePreview") private var showCodePreview: Bool = true
    @State private var istKopiert = false
    @State private var isHovered  = false

    private var codeVorschau: String {
        snippet.code
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(2)
            .joined(separator: "\n")
    }

    private var relativDatum: String {
        (snippet.lastAccessedAt ?? snippet.createdAt)
            .formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [snippet.akzentFarbe, snippet.akzentFarbe.opacity(0.3)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(alignment: .top, spacing: 9) {
                    FarbIcon(symbol: snippet.language.symbolName,
                             farbe: snippet.akzentFarbe, groesse: 26)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            if snippet.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                                    .rotationEffect(.degrees(45))
                            }
                            Text(snippet.title)
                                .font(.system(.subheadline, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        HStack(spacing: 3) {
                            Text(snippet.effectiveLanguageName)
                                .font(.caption2).fontWeight(.medium)
                                .foregroundStyle(snippet.akzentFarbe)
                            if !snippet.topic.isEmpty {
                                Text("·").foregroundStyle(.quaternary).font(.caption2)
                                Text(snippet.topic)
                                    .font(.caption2).foregroundStyle(.secondary)
                                    .lineLimit(1).truncationMode(.tail)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            if snippet.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9)).foregroundStyle(.yellow)
                            }
                            SchwierigkeitSterne(stufe: snippet.difficulty)
                        }
                        Text(relativDatum)
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }

                // Tags
                if !snippet.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(snippet.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 9))
                                .foregroundStyle(.purple.opacity(0.9))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        if snippet.tags.count > 3 {
                            Text("+\(snippet.tags.count - 3)")
                                .font(.system(size: 9)).foregroundStyle(.tertiary)
                        }
                    }
                }

                // Code-Vorschau
                if showCodePreview && !codeVorschau.isEmpty {
                    Text(codeVorschau)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.85))
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .padding(.horizontal, 11).padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(istAusgewaehlt
                      ? snippet.akzentFarbe.opacity(0.1)
                      : Color(nsColor: .controlBackgroundColor))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    istAusgewaehlt ? snippet.akzentFarbe.opacity(0.4) : Color.primary.opacity(0.07),
                    lineWidth: istAusgewaehlt ? 1.5 : 0.5
                )
        )
        .shadow(
            color: istAusgewaehlt ? snippet.akzentFarbe.opacity(0.18)
                                  : isHovered ? Color.black.opacity(0.07) : Color.black.opacity(0.03),
            radius: istAusgewaehlt ? 8 : isHovered ? 4 : 1,
            x: 0, y: istAusgewaehlt ? 3 : 1
        )
        .overlay(alignment: .topTrailing) {
            if isHovered || istKopiert {
                Button { kopieren() } label: {
                    Image(systemName: istKopiert ? "checkmark" : "doc.on.doc")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundStyle(istKopiert ? .green : .secondary)
                        .padding(6)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain).padding(7)
                .transition(.opacity.combined(with: .scale(0.85, anchor: .topTrailing)))
            }
        }
        .scaleEffect(isHovered && !istAusgewaehlt ? 1.003 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: istAusgewaehlt)
    }

    private func kopieren() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)
        istKopiert = true
        Task { try? await Task.sleep(for: .seconds(1.5)); istKopiert = false }
    }
}
