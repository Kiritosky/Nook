//
//  AddSnippetView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct AddSnippetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var titel = ""
    @State private var code = ""
    @State private var sprache: Language = .swift
    @State private var thema = ""
    @State private var projekt = ""
    @State private var schwierigkeit = 1
    @State private var beschreibung = ""
    @State private var output = ""
    @State private var tagsText = ""

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
                    TextField("Thema (z.B. Algorithmen, UI, API)", text: $thema)
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
                    TextField("Tags (kommagetrennt, z.B. array,sort,performance)", text: $tagsText)
                }
            }
            .navigationTitle("Neues Snippet")
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

        let snippet = Snippet(
            title: titel.trimmingCharacters(in: .whitespaces),
            code: code,
            language: sprache,
            topic: thema,
            project: projekt.isEmpty ? nil : projekt,
            difficulty: schwierigkeit,
            tags: tags,
            descriptionText: beschreibung.isEmpty ? nil : beschreibung,
            output: output.isEmpty ? nil : output
        )
        modelContext.insert(snippet)
        dismiss()
    }
}
