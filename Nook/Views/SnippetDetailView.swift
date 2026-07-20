//
//  SnippetDetailView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct SnippetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var snippet: Snippet

    @State private var bearbeitenAnzeigen = false
    @State private var loeschenBestaetigen = false
    @State private var kodeCopied = false

    private let schwierigkeitLabels = ["", "Anfänger", "Mittel", "Fortgeschritten"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Kopfbereich
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(snippet.title)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack(spacing: 6) {
                            TagPill(text: snippet.language.rawValue, farbe: .blue)
                            if snippet.difficulty >= 1 && snippet.difficulty <= 3 {
                                TagPill(text: schwierigkeitLabels[snippet.difficulty], farbe: .orange)
                            }
                            if let projekt = snippet.project, !projekt.isEmpty {
                                TagPill(text: projekt, farbe: .purple)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        snippet.isFavorite.toggle()
                    } label: {
                        Image(systemName: snippet.isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(snippet.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Code-Block mit Syntax Highlighting und Copy-Toast
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Code")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            kopieren()
                        } label: {
                            Label(
                                kodeCopied ? "Kopiert!" : "Kopieren",
                                systemImage: kodeCopied ? "checkmark" : "doc.on.doc"
                            )
                            .font(.caption)
                            .foregroundStyle(kodeCopied ? .green : .secondary)
                            .animation(.easeInOut(duration: 0.2), value: kodeCopied)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                    }

                    CodeHighlightView(code: snippet.code, language: snippet.language)
                }

                // Beschreibung
                if let beschreibung = snippet.descriptionText, !beschreibung.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Beschreibung")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(beschreibung)
                            .font(.body)
                    }
                }

                // Beispiel-Output
                if let output = snippet.output, !output.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Beispiel-Output")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(output)
                            .font(.system(.body, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Tags
                if !snippet.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tags")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach(snippet.tags, id: \.self) { tag in
                                TagPill(text: "#\(tag)", farbe: .gray)
                            }
                        }
                    }
                }

                Spacer()

                Text("Erstellt am \(snippet.createdAt.formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    bearbeitenAnzeigen = true
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                .keyboardShortcut("e", modifiers: .command)
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    loeschenBestaetigen = true
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $bearbeitenAnzeigen) {
            EditSnippetView(snippet: snippet)
        }
        .confirmationDialog(
            "Snippet löschen?",
            isPresented: $loeschenBestaetigen,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                modelContext.delete(snippet)
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("\"\(snippet.title)\" wird unwiderruflich gelöscht.")
        }
    }

    private func kopieren() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)
        kodeCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            kodeCopied = false
        }
    }
}
