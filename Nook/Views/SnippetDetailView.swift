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
            VStack(alignment: .leading, spacing: 0) {
                // MARK: – Getönter Header
                headerBereich

                // MARK: – Inhalt
                VStack(alignment: .leading, spacing: 28) {
                    codeBereich

                    if let text = snippet.descriptionText, !text.isEmpty {
                        infoSektion(titel: "Beschreibung") {
                            Text(text)
                                .font(.body)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    TagPill(text: "#\(tag)", farbe: .purple)
                                }
                            }
                        }
                    }

                    // Metadaten-Footer
                    HStack(spacing: 16) {
                        Label(snippet.createdAt.formatted(date: .long, time: .omitted),
                              systemImage: "calendar")
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
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) { loeschenBestaetigen = true } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $bearbeitenAnzeigen) {
            EditSnippetView(snippet: snippet)
        }
        .confirmationDialog("Snippet löschen?", isPresented: $loeschenBestaetigen, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { modelContext.delete(snippet) }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("\"\(snippet.title)\" wird unwiderruflich gelöscht.")
        }
    }

    // MARK: – Header

    private var headerBereich: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient-Hintergrund mit Sprachfarbe
            LinearGradient(
                colors: [snippet.akzentFarbe.opacity(0.22), snippet.akzentFarbe.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                // Dekoratives großes Icon im Hintergrund
                Image(systemName: snippet.language.symbolName)
                    .font(.system(size: 90, weight: .black))
                    .foregroundStyle(snippet.akzentFarbe.opacity(0.07))
                    .padding(20)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Sprach-Badge + Favorit
                HStack {
                    HStack(spacing: 6) {
                        FarbIcon(symbol: snippet.language.symbolName, farbe: snippet.akzentFarbe, groesse: 22)
                        Text(snippet.effectiveLanguageName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(snippet.akzentFarbe)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(snippet.akzentFarbe.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    Button {
                        snippet.isFavorite.toggle()
                    } label: {
                        Image(systemName: snippet.isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(snippet.isFavorite ? Color.yellow : Color.secondary.opacity(0.5))
                            .symbolEffect(.bounce, value: snippet.isFavorite)
                    }
                    .buttonStyle(.plain)
                }

                // Titel
                Text(snippet.title)
                    .font(.system(size: 26, weight: .bold, design: .default))
                    .lineLimit(3)

                // Metadaten-Zeile
                HStack(spacing: 10) {
                    if snippet.difficulty >= 1 && snippet.difficulty <= 3 {
                        HStack(spacing: 4) {
                            SchwierigkeitSterne(stufe: snippet.difficulty)
                            Text(schwierigkeitLabels[snippet.difficulty])
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if !snippet.topic.isEmpty {
                        Text("·").foregroundStyle(.quaternary)
                        Text(snippet.topic)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Code

    private var codeBereich: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(titel: "Code")
                Spacer()
                Button { kopieren() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: kodeCopied ? "checkmark" : "doc.on.doc")
                        Text(kodeCopied ? "Kopiert!" : "Kopieren")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(kodeCopied ? .green : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: kodeCopied)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            CodeHighlightView(code: snippet.code, highlightName: snippet.effectiveHighlightName)
        }
    }

    // MARK: – Sektion-Wrapper

    @ViewBuilder
    private func infoSektion<C: View>(titel: String, @ViewBuilder inhalt: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(titel: titel)
            inhalt()
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
