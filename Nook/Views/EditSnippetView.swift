//
//  EditSnippetView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct EditSnippetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var snippet: Snippet
    @Query(sort: \CustomLanguage.name) private var customLanguages: [CustomLanguage]
    @Query(sort: \Projekt.name) private var projekte: [Projekt]
    @Query(filter: #Predicate<Snippet> { $0.deletedAt == nil }) private var alleSnippets: [Snippet]

    private var vorhandeneThemen: [String] { Array(Set(alleSnippets.flatMap { $0.themen })) }
    private var vorhandeneTags: [String]   { Array(Set(alleSnippets.flatMap { $0.tags })) }

    @State private var titel: String
    @State private var code: String
    @State private var spracheName: String
    @State private var thema: String
    @State private var projektName: String
    @State private var schwierigkeit: Int
    @State private var beschreibung: String
    @State private var outputText: String
    @State private var tagsText: String

    init(snippet: Snippet) {
        self.snippet = snippet
        _titel        = State(initialValue: snippet.title)
        _code         = State(initialValue: snippet.code)
        _spracheName  = State(initialValue: snippet.effectiveLanguageName)
        _thema        = State(initialValue: snippet.topic)
        _projektName  = State(initialValue: snippet.project ?? "")
        _schwierigkeit = State(initialValue: snippet.difficulty)
        _beschreibung  = State(initialValue: snippet.descriptionText ?? "")
        _outputText    = State(initialValue: snippet.output ?? "")
        _tagsText      = State(initialValue: snippet.tags.joined(separator: ", "))
    }

    private var kannSpeichern: Bool {
        !titel.trimmingCharacters(in: .whitespaces).isEmpty &&
        !code.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var gewaehlteFarbe: Color {
        Language(rawValue: spracheName)?.farbe ?? .indigo
    }

    private var gewaehltesSymbol: String {
        Language(rawValue: spracheName)?.symbolName
            ?? customLanguages.first { $0.name == spracheName }?.symbolName
            ?? "doc.text"
    }

    private var effectiveHighlightName: String {
        Language(rawValue: spracheName)?.highlightName
            ?? customLanguages.first { $0.name == spracheName }?.highlightName
            ?? "plaintext"
    }

    var body: some View {
        HStack(spacing: 0) {
            linkeMetadaten
                .frame(width: 310)
            Divider()
            rechterCodeEditor
        }
        .frame(minWidth: 860, minHeight: 560)
    }

    // MARK: - Linke Spalte

    private var linkeMetadaten: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                FarbIcon(symbol: gewaehltesSymbol, farbe: gewaehlteFarbe, groesse: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snippet bearbeiten").font(.headline)
                    Text(spracheName).font(.caption).foregroundStyle(gewaehlteFarbe)
                }
                Spacer()
            }
            .padding(16)
            .background(gewaehlteFarbe.opacity(0.1))
            .animation(.easeInOut(duration: 0.2), value: spracheName)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    feldSektion("Titel") {
                        TextField("z.B. Binary Search in Python", text: $titel)
                            .textFieldStyle(.roundedBorder)
                    }

                    feldSektion("Sprache") {
                        ForEach(Language.gruppen, id: \.titel) { gruppe in
                            if gruppe.titel != Language.gruppen.first?.titel {
                                Divider().padding(.top, 4)
                            }
                            Text(LocalizedStringKey(gruppe.titel)).textCase(.uppercase)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.tertiary).tracking(0.5)
                                .padding(.top, 2)
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                                spacing: 6
                            ) {
                                ForEach(gruppe.sprachen, id: \.self) { lang in
                                    spracheButton(name: lang.rawValue, symbol: lang.symbolName, farbe: lang.farbe)
                                }
                            }
                        }
                        if !customLanguages.isEmpty {
                            Divider().padding(.top, 4)
                            Text("EIGENE")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.tertiary).tracking(0.5).padding(.top, 2)
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                                spacing: 6
                            ) {
                                ForEach(customLanguages) { lang in
                                    spracheButton(name: lang.name, symbol: lang.symbolName, farbe: .indigo)
                                }
                            }
                        }
                    }

                    feldSektion("Thema") {
                        TextField("z.B. Algorithmen, Netzwerk, UI", text: $thema)
                            .textFieldStyle(.roundedBorder)
                        Text("Mehrere Themen mit Komma trennen")
                            .font(.caption2).foregroundStyle(.tertiary)
                        VorschlagsChips(alle: vorhandeneThemen, text: $thema, farbe: .teal)
                    }

                    feldSektion("Projekt") {
                        projektPicker
                    }

                    feldSektion("Schwierigkeit") {
                        HStack(spacing: 6) {
                            ForEach(1...3, id: \.self) { stufe in
                                Button { schwierigkeit = stufe } label: {
                                    VStack(spacing: 3) {
                                        SchwierigkeitSterne(stufe: stufe)
                                        Text(LocalizedStringKey(["", "Anfänger", "Mittel", "Profi"][stufe]))
                                            .font(.system(size: 9))
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .background(schwierigkeit == stufe ? gewaehlteFarbe.opacity(0.15) : Color.clear)
                                    .overlay(RoundedRectangle(cornerRadius: 7)
                                        .stroke(schwierigkeit == stufe
                                                ? gewaehlteFarbe.opacity(0.5)
                                                : Color.secondary.opacity(0.18), lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    feldSektion("Tags") {
                        TextField("array, sort, performance", text: $tagsText)
                            .textFieldStyle(.roundedBorder)
                        Text("Mehrere Tags mit Komma trennen")
                            .font(.caption2).foregroundStyle(.tertiary)
                        VorschlagsChips(alle: vorhandeneTags, text: $tagsText, farbe: .purple)
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Speichern") { speichern() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!kannSpeichern)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(12)
        }
    }

    // MARK: - Projekt-Picker

    private var projektPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button { projektName = "" } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle").font(.system(size: 9))
                        Text("Keins")
                            .font(.caption)
                            .fontWeight(projektName.isEmpty ? .semibold : .regular)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(projektName.isEmpty
                                ? Color.secondary.opacity(0.2)
                                : Color.secondary.opacity(0.07))
                    .foregroundStyle(projektName.isEmpty ? Color.primary : Color.secondary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(
                        projektName.isEmpty ? Color.secondary.opacity(0.4) : Color.secondary.opacity(0.15),
                        lineWidth: projektName.isEmpty ? 1.5 : 0.5
                    ))
                }
                .buttonStyle(.plain)

                ForEach(projekte) { p in
                    ProjektPill(
                        name: p.name,
                        farbe: p.farbe,
                        symbol: p.symbolName,
                        aktiv: projektName == p.name
                    ) { projektName = p.name }
                }

                if projekte.isEmpty {
                    Text("Projekte in Einstellungen → Projekte anlegen")
                        .font(.caption2).foregroundStyle(.tertiary).fixedSize()
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Rechte Spalte (Code)

    private var rechterCodeEditor: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Code").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                if !code.isEmpty {
                    Text("\(code.components(separatedBy: "\n").count) Zeilen")
                        .font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Color.primary.opacity(0.03))

            Divider()

            // Nativer Code-Editor mit Live-Highlighting
            SyntaxTextEditor(text: $code, highlightName: effectiveHighlightName)

            Divider()

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: "text.alignleft").font(.caption2).foregroundStyle(.tertiary).padding(.top, 2)
                    TextField("Beschreibung (optional)", text: $beschreibung, axis: .vertical)
                        .textFieldStyle(.plain).font(.callout).lineLimit(2...4)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)

                Divider()

                HStack(alignment: .top) {
                    Image(systemName: "terminal").font(.caption2).foregroundStyle(.tertiary).padding(.top, 2)
                    TextField("Beispiel-Output (optional)", text: $outputText, axis: .vertical)
                        .textFieldStyle(.plain).font(.system(.caption, design: .monospaced)).lineLimit(2...3)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
            }
            .background(Color.primary.opacity(0.02))
        }
    }

    // MARK: - Hilfskomponenten

    @ViewBuilder
    private func feldSektion<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(label)).textCase(.uppercase)
                .font(.caption2).fontWeight(.semibold).foregroundStyle(.tertiary).tracking(0.5)
            content()
        }
    }

    @ViewBuilder
    private func spracheButton(name: String, symbol: String, farbe: Color) -> some View {
        let gewaehlt = spracheName == name
        Button { spracheName = name } label: {
            VStack(spacing: 4) {
                FarbIcon(symbol: symbol, farbe: gewaehlt ? farbe : .secondary.opacity(0.6), groesse: 28)
                Text(name).font(.system(size: 9)).lineLimit(1)
                    .foregroundStyle(gewaehlt ? farbe : Color.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 6)
            .background(gewaehlt ? farbe.opacity(0.12) : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(gewaehlt ? farbe.opacity(0.45) : Color.clear, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeInOut(duration: 0.15), value: gewaehlt)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Speichern

    private func speichern() {
        let tags = tagsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let themen = thema.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let builtIn = Language(rawValue: spracheName)
        let customHighlight = customLanguages.first { $0.name == spracheName }?.highlightName

        snippet.title           = titel.trimmingCharacters(in: .whitespaces)
        snippet.code            = code
        snippet.language        = builtIn ?? .other
        snippet.topic           = themen.joined(separator: ", ")
        snippet.project         = projektName.isEmpty ? nil : projektName
        snippet.difficulty      = schwierigkeit
        snippet.tags            = tags
        snippet.descriptionText = beschreibung.isEmpty ? nil : beschreibung
        snippet.output          = outputText.isEmpty ? nil : outputText
        snippet.languageOverride    = builtIn != nil ? nil : spracheName
        snippet.customHighlightName = customHighlight

        SpotlightManager.index(snippet)
        dismiss()
    }
}
