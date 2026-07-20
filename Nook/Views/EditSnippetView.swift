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
    @State private var output: String
    @State private var tagsText: String

    init(snippet: Snippet) {
        self.snippet = snippet
        _titel = State(initialValue: snippet.title)
        _code = State(initialValue: snippet.code)
        _spracheName = State(initialValue: snippet.effectiveLanguageName)
        _thema = State(initialValue: snippet.topic)
        _projekt = State(initialValue: snippet.project ?? "")
        _schwierigkeit = State(initialValue: snippet.difficulty)
        _beschreibung = State(initialValue: snippet.descriptionText ?? "")
        _output = State(initialValue: snippet.output ?? "")
        _tagsText = State(initialValue: snippet.tags.joined(separator: ", "))
    }

    private var kannSpeichern: Bool {
        !titel.trimmingCharacters(in: .whitespaces).isEmpty &&
        !code.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Grundlegende Infos") {
                    TextField("Titel", text: $titel)

                    Picker("Sprache", selection: $spracheName) {
                        Section("Eingebaut") {
                            ForEach(Language.allCases, id: \.self) { lang in
                                Label(lang.rawValue, systemImage: lang.symbolName)
                                    .tag(lang.rawValue)
                            }
                        }
                        if !customLanguages.isEmpty {
                            Section("Eigene") {
                                ForEach(customLanguages) { lang in
                                    Label(lang.name, systemImage: lang.symbolName)
                                        .tag(lang.name)
                                }
                            }
                        }
                    }

                    TextField("Thema", text: $thema)
                    TextField("Projekt (optional)", text: $projekt)

                    Picker("Schwierigkeit", selection: $schwierigkeit) {
                        HStack { SchwierigkeitSterne(stufe: 1); Text("Anfänger") }.tag(1)
                        HStack { SchwierigkeitSterne(stufe: 2); Text("Mittel") }.tag(2)
                        HStack { SchwierigkeitSterne(stufe: 3); Text("Fortgeschritten") }.tag(3)
                    }
                }

                Section("Code") {
                    TextEditor(text: $code)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 180)
                }

                Section("Weitere Details (optional)") {
                    TextField("Beschreibung", text: $beschreibung, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Beispiel-Output", text: $output, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Tags (kommagetrennt)", text: $tagsText)
                }
            }
            .navigationTitle("Snippet bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                        .disabled(!kannSpeichern)
                }
            }
        }
        .frame(minWidth: 520, minHeight: 640)
    }

    private func speichern() {
        let tags = tagsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let builtIn = Language(rawValue: spracheName)
        let customHighlight = customLanguages.first { $0.name == spracheName }?.highlightName

        snippet.title = titel.trimmingCharacters(in: .whitespaces)
        snippet.code = code
        snippet.language = builtIn ?? .other
        snippet.topic = thema
        snippet.project = projekt.isEmpty ? nil : projekt
        snippet.difficulty = schwierigkeit
        snippet.tags = tags
        snippet.descriptionText = beschreibung.isEmpty ? nil : beschreibung
        snippet.output = output.isEmpty ? nil : output
        snippet.languageOverride = builtIn != nil ? nil : spracheName
        snippet.customHighlightName = customHighlight

        dismiss()
    }
}
