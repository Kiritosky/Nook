//
//  SnippetListView.swift
//  Nook
//

import SwiftUI
import SwiftData

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
    @Query private var alleSnippets: [Snippet]

    let sidebarItem: SidebarItem
    @Binding var selectedSnippet: Snippet?
    @Binding var addSnippetAnzeigen: Bool
    @Binding var tagFilter: String?

    @State private var suchtext = ""
    @State private var schwierigkeitsFilter: Int? = nil
    @AppStorage("snippetSortierung") private var sortierung: Sortierung = .neueste

    private var basisSnippets: [Snippet] {
        let gefiltert: [Snippet]
        switch sidebarItem {
        case .alle:                    gefiltert = alleSnippets
        case .favoriten:               gefiltert = alleSnippets.filter { $0.isFavorite }
        case .sprache(let lang):       gefiltert = alleSnippets.filter { $0.language == lang && $0.languageOverride == nil }
        case .customSprache(let name): gefiltert = alleSnippets.filter { $0.languageOverride == name }
        case .projekt(let proj):       gefiltert = alleSnippets.filter { $0.project == proj }
        }

        let sortiert: [Snippet]
        switch sortierung {
        case .neueste:         sortiert = gefiltert.sorted { $0.createdAt > $1.createdAt }
        case .aelteste:        sortiert = gefiltert.sorted { $0.createdAt < $1.createdAt }
        case .titel:           sortiert = gefiltert.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .zuleztGeoeffnet: sortiert = gefiltert.sorted { ($0.lastAccessedAt ?? $0.createdAt) > ($1.lastAccessedAt ?? $1.createdAt) }
        }

        return sortiert.sorted { $0.isPinned && !$1.isPinned }
    }

    private var gefilterteSnippets: [Snippet] {
        var r = basisSnippets
        if let s = schwierigkeitsFilter { r = r.filter { $0.difficulty == s } }
        if let tag = tagFilter { r = r.filter { $0.tags.contains(tag) } }
        guard !suchtext.isEmpty else { return r }
        return r.filter {
            $0.title.localizedCaseInsensitiveContains(suchtext) ||
            $0.topic.localizedCaseInsensitiveContains(suchtext) ||
            $0.code.localizedCaseInsensitiveContains(suchtext) ||
            $0.effectiveLanguageName.localizedCaseInsensitiveContains(suchtext) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(suchtext)
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
                    FilterChip(label: "Alle",          symbol: "square.grid.2x2",      aktiv: schwierigkeitsFilter == nil) { schwierigkeitsFilter = nil }
                    FilterChip(label: "Anfänger",      symbol: "circle.fill",           aktiv: schwierigkeitsFilter == 1)   { schwierigkeitsFilter = schwierigkeitsFilter == 1 ? nil : 1 }
                    FilterChip(label: "Mittel",        symbol: "circle.lefthalf.filled", aktiv: schwierigkeitsFilter == 2)  { schwierigkeitsFilter = schwierigkeitsFilter == 2 ? nil : 2 }
                    FilterChip(label: "Fortgeschritten", symbol: "record.circle",       aktiv: schwierigkeitsFilter == 3)   { schwierigkeitsFilter = schwierigkeitsFilter == 3 ? nil : 3 }
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
            }
            .background(.bar)

            Divider()

            if gefilterteSnippets.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(gefilterteSnippets) { snippet in
                            SnippetKarte(snippet: snippet, istAusgewaehlt: selectedSnippet == snippet)
                                .onTapGesture { selectedSnippet = snippet }
                                .contextMenu {
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
                                        SpotlightManager.remove(snippet)
                                        modelContext.delete(snippet)
                                        if selectedSnippet == snippet { selectedSnippet = nil }
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 10)
                }
            }
        }
        .searchable(text: $suchtext, prompt: "Suchen...")
        .navigationTitle(titelFuerAuswahl)
        .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { addSnippetAnzeigen = true } label: {
                    Label("Hinzufügen", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
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
        case .sprache(let lang):       return lang.rawValue
        case .customSprache(let name): return name
        case .projekt(let proj):       return proj
        }
    }

    private var emptyState: some View {
        let istLeer     = alleSnippets.isEmpty
        let istTagFilter = tagFilter != nil
        let istSuche    = !suchtext.isEmpty

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
            // Akzentbalken
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

                    // Titel + Untertitel
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

                    // Rechts: Stern + Sterne + Datum (fixiert)
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
