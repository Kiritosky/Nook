//
//  SnippetDetailView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct SnippetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var snippet: Snippet
    @Binding var tagFilter: String?

    @AppStorage("syntaxTheme") private var syntaxTheme: SyntaxTheme = .catppuccinMocha

    @State private var bearbeitenAnzeigen = false
    @State private var loeschenBestaetigen = false
    @State private var kodeCopied = false
    @State private var markdownCopied = false
    @State private var shortcutsAnzeigen = false

    private let schwierigkeitLabels = ["", "Anfänger", "Mittel", "Fortgeschritten"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerBereich
                VStack(alignment: .leading, spacing: 28) {
                    codeBereich

                    if let text = snippet.descriptionText, !text.isEmpty {
                        infoSektion(titel: "Beschreibung") {
                            Text(text)
                                .font(.body)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color.primary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.06), lineWidth: 0.5))
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
                            HStack(spacing: 6) {
                                ForEach(snippet.tags, id: \.self) { tag in
                                    Button {
                                        tagFilter = tag
                                    } label: {
                                        TagPill(text: "#\(tag)", farbe: .purple)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Nach #\(tag) filtern")
                                }
                            }
                        }
                    }

                    // Metadaten-Footer
                    HStack(spacing: 16) {
                        Label(snippet.createdAt.formatted(date: .long, time: .omitted),
                              systemImage: "calendar")
                        if let last = snippet.lastAccessedAt {
                            Label("Zuletzt: \(last.formatted(.relative(presentation: .named)))",
                                  systemImage: "eye")
                        }
                        if let projekt = snippet.project, !projekt.isEmpty {
                            Label(projekt, systemImage: "folder")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.quaternary)
                }
                .padding(28)
            }
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
                .help("Als Markdown in die Zwischenablage kopieren")
            }

            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) { loeschenBestaetigen = true } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $bearbeitenAnzeigen) {
            EditSnippetView(snippet: snippet)
        }
        .sheet(isPresented: $shortcutsAnzeigen) {
            ShortcutsOverlay()
        }
        .confirmationDialog("Snippet löschen?", isPresented: $loeschenBestaetigen, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                SpotlightManager.remove(snippet)
                modelContext.delete(snippet)
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("\"\(snippet.title)\" wird unwiderruflich gelöscht.")
        }
        .onAppear {
            snippet.lastAccessedAt = Date()
        }
        .onKeyPress(.init("?")) {
            shortcutsAnzeigen = true
            return .handled
        }
    }

    // MARK: - Header

    private var headerBereich: some View {
        ZStack(alignment: .bottomLeading) {
            // Mehrschichtiger Gradient für Tiefe
            LinearGradient(
                stops: [
                    .init(color: snippet.akzentFarbe.opacity(0.28), location: 0),
                    .init(color: snippet.akzentFarbe.opacity(0.12), location: 0.5),
                    .init(color: snippet.akzentFarbe.opacity(0.02), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Großes dekoratives Symbol
            Image(systemName: snippet.language.symbolName)
                .font(.system(size: 140, weight: .black))
                .foregroundStyle(snippet.akzentFarbe.opacity(0.06))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 16)
                .padding(.trailing, 20)

            VStack(alignment: .leading, spacing: 14) {
                // Aktions-Leiste oben
                HStack(spacing: 10) {
                    // Sprach-Badge
                    HStack(spacing: 6) {
                        FarbIcon(symbol: snippet.language.symbolName, farbe: snippet.akzentFarbe, groesse: 20)
                        Text(snippet.effectiveLanguageName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(snippet.akzentFarbe)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(snippet.akzentFarbe.opacity(0.13))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(snippet.akzentFarbe.opacity(0.2), lineWidth: 0.5))

                    Spacer()

                    // Pin
                    headerButton(
                        symbol: snippet.isPinned ? "pin.fill" : "pin",
                        farbe: snippet.isPinned ? .orange : .secondary.opacity(0.5),
                        rotation: snippet.isPinned ? 45 : 0,
                        help: snippet.isPinned ? "Losgelöst" : "Anheften"
                    ) { snippet.isPinned.toggle() }

                    // Favorit
                    headerButton(
                        symbol: snippet.isFavorite ? "star.fill" : "star",
                        farbe: snippet.isFavorite ? .yellow : .secondary.opacity(0.5),
                        help: snippet.isFavorite ? "Aus Favoriten" : "Favorit"
                    ) { snippet.isFavorite.toggle() }
                }

                // Titel
                Text(snippet.title)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Metadaten-Chips
                HStack(spacing: 6) {
                    if snippet.difficulty >= 1 && snippet.difficulty <= 3 {
                        metaChip {
                            HStack(spacing: 4) {
                                SchwierigkeitSterne(stufe: snippet.difficulty)
                                Text(schwierigkeitLabels[snippet.difficulty])
                                    .font(.caption2).fontWeight(.medium)
                            }
                        }
                    }
                    if !snippet.topic.isEmpty {
                        metaChip {
                            Label(snippet.topic, systemImage: "tag")
                                .font(.caption2)
                        }
                    }
                    if let proj = snippet.project, !proj.isEmpty {
                        metaChip {
                            Label(proj, systemImage: "folder")
                                .font(.caption2)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func headerButton(
        symbol: String,
        farbe: Color,
        rotation: Double = 0,
        help: String,
        aktion: @escaping () -> Void
    ) -> some View {
        Button(action: aktion) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(farbe)
                .rotationEffect(.degrees(rotation))
                .symbolEffect(.bounce, value: symbol)
                .frame(width: 32, height: 32)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    @ViewBuilder
    private func metaChip<C: View>(@ViewBuilder inhalt: () -> C) -> some View {
        inhalt()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.06))
            .clipShape(Capsule())
    }

    // MARK: - Code (Terminal-Stil)

    private var codeBereich: some View {
        VStack(spacing: 0) {
            // Terminal-Header
            HStack(spacing: 0) {
                // Mac-Dots (dekorativ)
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: "FF5F57")).frame(width: 9, height: 9)
                    Circle().fill(Color(hex: "FFBD2E")).frame(width: 9, height: 9)
                    Circle().fill(Color(hex: "28CA41")).frame(width: 9, height: 9)
                }
                .padding(.leading, 14)

                Spacer()

                // Sprache + Icon
                HStack(spacing: 5) {
                    FarbIcon(symbol: snippet.language.symbolName, farbe: snippet.akzentFarbe, groesse: 14)
                    Text(snippet.effectiveLanguageName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                // Zeilen-Anzahl + Kopieren
                HStack(spacing: 10) {
                    Text("\(snippet.code.components(separatedBy: "\n").count) Z.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.25))
                        .monospacedDigit()

                    Button { kopieren() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: kodeCopied ? "checkmark" : "doc.on.doc")
                            Text(kodeCopied ? "Kopiert" : "Kopieren")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
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
                Color.black.opacity(0.25)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)
            }

            // Code-Inhalt
            CodeHighlightView(code: snippet.code, highlightName: snippet.effectiveHighlightName)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
        )
    }

    // MARK: - Sektion-Wrapper

    @ViewBuilder
    private func infoSektion<C: View>(titel: String, @ViewBuilder inhalt: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(titel: titel)
            inhalt()
        }
    }

    // MARK: - Aktionen

    private func kopieren() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)
        kodeCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            kodeCopied = false
        }
    }

    private func alsMarkdownKopieren() {
        var md = "## \(snippet.title)\n"

        let meta = [snippet.effectiveLanguageName, snippet.topic].filter { !$0.isEmpty }.joined(separator: " · ")
        if !meta.isEmpty { md += "> \(meta)\n" }

        md += "\n```\(snippet.effectiveHighlightName)\n\(snippet.code)\n```\n"

        if let desc = snippet.descriptionText, !desc.isEmpty {
            md += "\n\(desc)\n"
        }

        if let out = snippet.output, !out.isEmpty {
            md += "\n**Output:**\n```\n\(out)\n```\n"
        }

        if !snippet.tags.isEmpty {
            md += "\n*Tags: \(snippet.tags.map { "#\($0)" }.joined(separator: ", "))*\n"
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(md, forType: .string)
        markdownCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            markdownCopied = false
        }
    }
}

// MARK: - Shortcuts Overlay

struct ShortcutsOverlay: View {
    @Environment(\.dismiss) private var dismiss

    private let shortcuts: [(String, String)] = [
        ("⌘N", "Neues Snippet"),
        ("⌘E", "Snippet bearbeiten"),
        ("⇧⌘C", "Code kopieren"),
        ("⌘,", "Einstellungen öffnen"),
        ("?", "Diese Übersicht"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tastaturkürzel")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            VStack(spacing: 0) {
                ForEach(shortcuts, id: \.0) { kuerzel, beschreibung in
                    HStack {
                        Text(beschreibung)
                            .font(.callout)
                        Spacer()
                        Text(kuerzel)
                            .font(.system(.callout, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    if kuerzel != shortcuts.last?.0 {
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
    }
}
