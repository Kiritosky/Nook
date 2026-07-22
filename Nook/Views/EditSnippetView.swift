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

    @State private var titel: String
    @State private var code: String
    @State private var spracheName: String
    @State private var thema: String
    @State private var projekt: String
    @State private var schwierigkeit: Int
    @State private var beschreibung: String
    @State private var outputText: String
    @State private var tagsText: String

    init(snippet: Snippet) {
        self.snippet = snippet
        _titel       = State(initialValue: snippet.title)
        _code        = State(initialValue: snippet.code)
        _spracheName = State(initialValue: snippet.effectiveLanguageName)
        _thema       = State(initialValue: snippet.topic)
        _projekt     = State(initialValue: snippet.project ?? "")
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

    var body: some View {
        HStack(spacing: 0) {
            linkeMetadaten
                .frame(width: 310)
            Divider()
            rechterCodeEditor
        }
        .frame(minWidth: 860, minHeight: 560)
    }

    // MARK: - Linke Spalte (Metadaten)

    private var linkeMetadaten: some View {
        VStack(spacing: 0) {
            // Farbiger Header
            HStack(spacing: 12) {
                FarbIcon(symbol: gewaehltesSymbol, farbe: gewaehlteFarbe, groesse: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snippet bearbeiten")
                        .font(.headline)
                    Text(spracheName)
                        .font(.caption)
                        .foregroundStyle(gewaehlteFarbe)
                }
                Spacer()
            }
            .padding(16)
            .background(gewaehlteFarbe.opacity(0.1))
            .animation(.easeInOut(duration: 0.2), value: spracheName)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Titel
                    feldSektion("Titel") {
                        TextField("z.B. Binary Search in Python", text: $titel)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Sprachauswahl
                    feldSektion("Sprache") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                            spacing: 6
                        ) {
                            ForEach(Language.allCases, id: \.self) { lang in
                                spracheButton(name: lang.rawValue, symbol: lang.symbolName, farbe: lang.farbe)
                            }
                        }

                        if !customLanguages.isEmpty {
                            Text("EIGENE")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.tertiary)
                                .tracking(0.5)
                                .padding(.top, 4)
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

                    // Thema
                    feldSektion("Thema") {
                        TextField("z.B. Algorithmen, Netzwerk, UI", text: $thema)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Projekt
                    feldSektion("Projekt (optional)") {
                        TextField("z.B. MyApp, Studium", text: $projekt)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Schwierigkeit
                    feldSektion("Schwierigkeit") {
                        HStack(spacing: 6) {
                            ForEach(1...3, id: \.self) { stufe in
                                Button { schwierigkeit = stufe } label: {
                                    VStack(spacing: 3) {
                                        SchwierigkeitSterne(stufe: stufe)
                                        Text(["", "Anfänger", "Mittel", "Profi"][stufe])
                                            .font(.system(size: 9))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(schwierigkeit == stufe ? gewaehlteFarbe.opacity(0.15) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(
                                                schwierigkeit == stufe
                                                    ? gewaehlteFarbe.opacity(0.5)
                                                    : Color.secondary.opacity(0.18),
                                                lineWidth: 1
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Tags
                    feldSektion("Tags (optional)") {
                        TextField("array, sort, performance", text: $tagsText)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(16)
            }

            Divider()

            // Buttons
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

    // MARK: - Rechte Spalte (Code)

    private var rechterCodeEditor: some View {
        VStack(spacing: 0) {
            // Code-Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Code")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if !code.isEmpty {
                    Text("\(code.components(separatedBy: "\n").count) Zeilen")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.primary.opacity(0.03))

            Divider()

            TextEditor(text: $code)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)

            Divider()

            // Beschreibung und Output als kompakte Footer-Felder
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: "text.alignleft")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                    TextField("Beschreibung (optional)", text: $beschreibung, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .lineLimit(2...4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)

                Divider()

                HStack(alignment: .top) {
                    Image(systemName: "terminal")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                    TextField("Beispiel-Output (optional)", text: $outputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2...3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
            }
            .background(Color.primary.opacity(0.02))
        }
    }

    // MARK: - Hilfskomponenten

    @ViewBuilder
    private func feldSektion<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            content()
        }
    }

    @ViewBuilder
    private func spracheButton(name: String, symbol: String, farbe: Color) -> some View {
        let gewaehlt = spracheName == name
        Button { spracheName = name } label: {
            VStack(spacing: 4) {
                FarbIcon(
                    symbol: symbol,
                    farbe: gewaehlt ? farbe : .secondary.opacity(0.6),
                    groesse: 28
                )
                Text(name)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .foregroundStyle(gewaehlt ? farbe : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(gewaehlt ? farbe.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(gewaehlt ? farbe.opacity(0.45) : Color.clear, lineWidth: 1.5)
            )
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

        let builtIn = Language(rawValue: spracheName)
        let customHighlight = customLanguages.first { $0.name == spracheName }?.highlightName

        snippet.title           = titel.trimmingCharacters(in: .whitespaces)
        snippet.code            = code
        snippet.language        = builtIn ?? .other
        snippet.topic           = thema
        snippet.project         = projekt.isEmpty ? nil : projekt
        snippet.difficulty      = schwierigkeit
        snippet.tags            = tags
        snippet.descriptionText = beschreibung.isEmpty ? nil : beschreibung
        snippet.output          = outputText.isEmpty ? nil : outputText
        snippet.languageOverride    = builtIn != nil ? nil : spracheName
        snippet.customHighlightName = customHighlight

        dismiss()
    }
}
