//
//  SnippetDetailView.swift
//  Nook
//

import SwiftUI
import SwiftData

// MARK: - Flex-Wrap für Tags

struct FlexiWrap: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(.unspecified)
            if x + s.width > width && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}

// MARK: - SnippetDetailView

struct SnippetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PapierkorbManager.self) private var papierkorb
    @Bindable var snippet: Snippet
    @Binding var tagFilter: String?

    @AppStorage("syntaxTheme") private var syntaxTheme: SyntaxTheme = .catppuccinMocha

    @State private var bearbeitenAnzeigen = false
    @State private var kodeCopied = false
    @State private var markdownCopied = false
    @State private var bildKopiert = false
    @State private var shortcutsAnzeigen = false

    private let schwierigkeitLabels = ["", "Anfänger", "Mittel", "Fortgeschritten"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header füllt immer die volle Spaltenbreite
                headerBereich

                // Body ist auf max. 960 px limitiert (lesbar bei ultrawide)
                VStack(alignment: .leading, spacing: 24) {
                    codeBereich

                    if let text = snippet.descriptionText, !text.isEmpty {
                        infoSektion(titel: "Beschreibung") {
                            Text(text)
                                .font(.body).lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color.primary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5))
                        }
                    }

                    if let out = snippet.output, !out.isEmpty {
                        infoSektion(titel: "Beispiel-Output") {
                            Text(out)
                                .font(.system(.callout, design: .monospaced))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if !snippet.tags.isEmpty {
                        infoSektion(titel: "Tags") {
                            FlexiWrap(spacing: 6) {
                                ForEach(snippet.tags, id: \.self) { tag in
                                    Button { tagFilter = tag } label: {
                                        TagPill(text: "#\(tag)", farbe: .purple)
                                    }
                                    .buttonStyle(.plain).help("Nach #\(tag) filtern")
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Label(snippet.createdAt.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                        if let last = snippet.lastAccessedAt {
                            Label(last.formatted(.relative(presentation: .named)),
                                  systemImage: "eye")
                        }
                        if snippet.copyCount > 0 {
                            Label("\(snippet.copyCount)×", systemImage: "doc.on.doc")
                        }
                        if let p = snippet.project, !p.isEmpty {
                            Label(p, systemImage: "folder")
                        }
                    }
                    .font(.caption).foregroundStyle(.quaternary).lineLimit(1)
                }
                .padding(24)
                // Lesbare Max-Breite – links ausgerichtet
                .frame(maxWidth: 960, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { bearbeitenAnzeigen = true } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                .keyboardShortcut("e", modifiers: .command)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { alsMarkdownKopieren() } label: {
                    Label(markdownCopied ? "Kopiert!" : "Markdown",
                          systemImage: markdownCopied ? "checkmark" : "doc.richtext")
                }
                .help("Als Markdown kopieren")
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        SnippetBildExport.speichern(snippet, theme: syntaxTheme)
                    } label: {
                        Label("Bild speichern …", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        bildKopiert = SnippetBildExport.kopieren(snippet, theme: syntaxTheme)
                        if bildKopiert {
                            Task { try? await Task.sleep(for: .seconds(1.5)); bildKopiert = false }
                        }
                    } label: {
                        Label("Bild kopieren", systemImage: "doc.on.doc")
                    }
                } label: {
                    Label(bildKopiert ? "Kopiert!" : "Als Bild",
                          systemImage: bildKopiert ? "checkmark" : "photo")
                }
                .help("Snippet als Bild teilen (Carbon-Stil)")
            }
            if snippet.imPapierkorb {
                ToolbarItem(placement: .primaryAction) {
                    Button { papierkorb.wiederherstellen(snippet) } label: {
                        Label("Wiederherstellen", systemImage: "arrow.uturn.backward")
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        papierkorb.endgueltigLoeschen(snippet, context: modelContext)
                    } label: {
                        Label("Endgültig löschen", systemImage: "trash")
                    }
                }
            } else {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { papierkorb.loeschen(snippet) } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                    .help("In den Papierkorb (mit Rückgängig)")
                }
            }
        }
        .sheet(isPresented: $bearbeitenAnzeigen) { EditSnippetView(snippet: snippet) }
        .sheet(isPresented: $shortcutsAnzeigen) { ShortcutsOverlay() }
        .onAppear { snippet.lastAccessedAt = Date() }
        .onKeyPress(.init("?")) { shortcutsAnzeigen = true; return .handled }
    }

    // MARK: - Header

    private var headerBereich: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                stops: [
                    .init(color: snippet.akzentFarbe.opacity(0.18), location: 0),
                    .init(color: snippet.akzentFarbe.opacity(0.05), location: 0.6),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            Image(systemName: snippet.language.symbolName)
                .font(.system(size: 80, weight: .heavy))
                .foregroundStyle(snippet.akzentFarbe.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 12).padding(.trailing, 20)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                // Sprache + Aktionsbuttons
                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 5) {
                        FarbIcon(symbol: snippet.language.symbolName,
                                 farbe: snippet.akzentFarbe, groesse: 18)
                        Text(snippet.effectiveLanguageName)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(snippet.akzentFarbe)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(snippet.akzentFarbe.opacity(0.12))
                    .clipShape(Capsule())
                    .fixedSize()

                    Spacer(minLength: 8)

                    headerButton(symbol: snippet.isPinned ? "pin.fill" : "pin",
                                 farbe: snippet.isPinned ? .orange : .secondary.opacity(0.4),
                                 rotation: snippet.isPinned ? 45 : 0,
                                 help: snippet.isPinned ? "Losgelöst" : "Anheften") {
                        snippet.isPinned.toggle()
                    }
                    headerButton(symbol: snippet.isFavorite ? "star.fill" : "star",
                                 farbe: snippet.isFavorite ? .yellow : .secondary.opacity(0.4),
                                 help: snippet.isFavorite ? "Aus Favoriten" : "Favorit") {
                        snippet.isFavorite.toggle()
                    }
                }

                // Titel
                Text(snippet.title)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)

                // Meta-Chips: wrappend statt HStack
                FlexiWrap(spacing: 5) {
                    if snippet.difficulty >= 1 && snippet.difficulty <= 3 {
                        metaChip {
                            HStack(spacing: 3) {
                                SchwierigkeitSterne(stufe: snippet.difficulty)
                                Text(schwierigkeitLabels[snippet.difficulty])
                                    .font(.caption2).fontWeight(.medium)
                            }
                        }
                    }
                    ForEach(snippet.themen, id: \.self) { thema in
                        metaChip {
                            Label(thema, systemImage: "tag")
                                .font(.caption2).lineLimit(1)
                        }
                    }
                    if let proj = snippet.project, !proj.isEmpty {
                        metaChip {
                            Label(proj, systemImage: "folder")
                                .font(.caption2).lineLimit(1)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(20)
            // Header-Inhalt auch max 960 px (konsistent mit Body)
            .frame(maxWidth: 960, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func headerButton(symbol: String, farbe: Color, rotation: Double = 0,
                              help: String, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundStyle(farbe)
                .rotationEffect(.degrees(rotation))
                .symbolEffect(.bounce, value: symbol)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())
        }
        .buttonStyle(.plain).help(help)
    }

    @ViewBuilder
    private func metaChip<C: View>(@ViewBuilder inhalt: () -> C) -> some View {
        inhalt()
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.primary.opacity(0.06))
            .clipShape(Capsule())
    }

    // MARK: - Code-Block

    private var codeBereich: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: "FF5F57")).frame(width: 9, height: 9)
                    Circle().fill(Color(hex: "FFBD2E")).frame(width: 9, height: 9)
                    Circle().fill(Color(hex: "28CA41")).frame(width: 9, height: 9)
                }
                .padding(.leading, 14)

                Spacer()

                HStack(spacing: 5) {
                    FarbIcon(symbol: snippet.language.symbolName,
                             farbe: snippet.akzentFarbe, groesse: 14)
                    Text(snippet.effectiveLanguageName)
                        .font(.caption).fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                HStack(spacing: 10) {
                    Text("\(snippet.code.components(separatedBy: "\n").count) Z.")
                        .font(.caption2).foregroundStyle(.white.opacity(0.25)).monospacedDigit()

                    Button { kopieren() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: kodeCopied ? "checkmark" : "doc.on.doc")
                            Text(kodeCopied ? "Kopiert" : "Kopieren")
                        }
                        .font(.caption).fontWeight(.medium)
                        .foregroundStyle(kodeCopied ? .green : .white.opacity(0.45))
                        .animation(.easeInOut(duration: 0.2), value: kodeCopied)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
                .padding(.trailing, 14)
            }
            .padding(.vertical, 10)
            .background {
                syntaxTheme.hintergrundFarbe
                Color.black.opacity(0.2)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
            }

            CodeHighlightView(code: snippet.code, highlightName: snippet.effectiveHighlightName)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }

    @ViewBuilder
    private func infoSektion<C: View>(titel: String, @ViewBuilder inhalt: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(titel: titel)
            inhalt()
        }
    }

    private func kopieren() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)
        snippet.copyCount += 1
        kodeCopied = true
        Task { try? await Task.sleep(for: .seconds(1.5)); kodeCopied = false }
    }

    private func alsMarkdownKopieren() {
        var md = "## \(snippet.title)\n"
        let meta = [snippet.effectiveLanguageName, snippet.topic].filter { !$0.isEmpty }.joined(separator: " · ")
        if !meta.isEmpty { md += "> \(meta)\n" }
        md += "\n```\(snippet.effectiveHighlightName)\n\(snippet.code)\n```\n"
        if let desc = snippet.descriptionText, !desc.isEmpty { md += "\n\(desc)\n" }
        if let out = snippet.output, !out.isEmpty { md += "\n**Output:**\n```\n\(out)\n```\n" }
        if !snippet.tags.isEmpty { md += "\n*Tags: \(snippet.tags.map { "#\($0)" }.joined(separator: ", "))*\n" }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(md, forType: .string)
        markdownCopied = true
        Task { try? await Task.sleep(for: .seconds(1.5)); markdownCopied = false }
    }
}

// MARK: - Shortcuts Overlay

struct ShortcutsOverlay: View {
    @Environment(\.dismiss) private var dismiss
    private let shortcuts: [(String, String)] = [
        ("⌘N", "Neues Snippet"), ("⌘E", "Snippet bearbeiten"),
        ("⇧⌘C", "Code kopieren"), ("⌘,", "Einstellungen"),
        ("⌘⇧Space", "Nook von überall aufrufen"), ("?", "Diese Übersicht"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tastaturkürzel").font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }
            .padding(20)
            Divider()
            VStack(spacing: 0) {
                ForEach(shortcuts, id: \.0) { k, b in
                    HStack {
                        Text(b).font(.callout)
                        Spacer()
                        Text(k)
                            .font(.system(.callout, design: .monospaced))
                            .fontWeight(.medium).foregroundStyle(.secondary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    if k != shortcuts.last?.0 { Divider().padding(.leading, 20) }
                }
            }
        }
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
    }
}
