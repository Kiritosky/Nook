//
//  EditSnippetView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct EditSnippetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var snippet: Snippet

    @State private var titel: String
    @State private var code: String
    @State private var sprache: Language
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
        _sprache = State(initialValue: snippet.language)
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
                    Picker("Sprache", selection: $sprache) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                    TextField("Thema", text: $thema)
                    TextField("Projekt (optional)", text: $projekt)
                    Picker("Schwierigkeit", selection: $schwierigkeit) {
                        Text("Anfänger").tag(1)
                        Text("Mittel").tag(2)
                        Text("Fortgeschritten").tag(3)
                    }
                }

                Section("Code") {
                    TextEditor(text: $code)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
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
        .frame(minWidth: 500, minHeight: 600)
    }

    private func speichern() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        snippet.title = titel.trimmingCharacters(in: .whitespaces)
        snippet.code = code
        snippet.language = sprache
        snippet.topic = thema
        snippet.project = projekt.isEmpty ? nil : projekt
        snippet.difficulty = schwierigkeit
        snippet.tags = tags
        snippet.descriptionText = beschreibung.isEmpty ? nil : beschreibung
        snippet.output = output.isEmpty ? nil : output

        dismiss()
    }
}
