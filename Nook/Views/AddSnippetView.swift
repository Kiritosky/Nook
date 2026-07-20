//
//  AddSnippetView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct AddSnippetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomLanguage.name) private var customLanguages: [CustomLanguage]

    @State private var titel = ""
    @State private var code = ""
    @State private var spracheName: String = Language.swift.rawValue
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

                    TextField("Thema (z.B. Algorithmen, UI, Netzwerk)", text: $thema)
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
        .frame(minWidth: 520, minHeight: 640)
    }

    private func speichern() {
        let tags = tagsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let builtIn = Language(rawValue: spracheName)
        let customHighlight = customLanguages.first { $0.name == spracheName }?.highlightName

        let snippet = Snippet(
            title: titel.trimmingCharacters(in: .whitespaces),
            code: code,
            language: builtIn ?? .other,
            topic: thema,
            project: projekt.isEmpty ? nil : projekt,
            difficulty: schwierigkeit,
            tags: tags,
            descriptionText: beschreibung.isEmpty ? nil : beschreibung,
            output: output.isEmpty ? nil : output,
            languageOverride: builtIn != nil ? nil : spracheName,
            customHighlightName: customHighlight
        )
        modelContext.insert(snippet)
        dismiss()
    }
}
