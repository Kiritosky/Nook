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
                // Header
                headerBereich
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                Divider()

                VStack(alignment: .leading, spacing: 24) {
                    // Code
                    codeBereich

                    // Beschreibung
                    if let text = snippet.descriptionText, !text.isEmpty {
                        infoBereich(titel: "Beschreibung") {
                            Text(text)
                                .font(.body)
                                .lineSpacing(3)
                        }
                    }

                    // Output
                    if let output = snippet.output, !output.isEmpty {
                        infoBereich(titel: "Beispiel-Output") {
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
                        infoBereich(titel: "Tags") {
                            HStack(spacing: 6) {
                                ForEach(snippet.tags, id: \.self) { tag in
                                    TagPill(text: "#\(tag)", farbe: .purple)
                                }
                            }
                        }
                    }

                    // Metadaten
                    HStack(spacing: 16) {
                        Label(snippet.createdAt.formatted(date: .long, time: .omitted),
                              systemImage: "calendar")
                        if let projekt = snippet.project, !projekt.isEmpty {
                            Label(projekt, systemImage: "folder")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .padding(28)
            }
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
        .confirmationDialog("Snippet löschen?",
                            isPresented: $loeschenBestaetigen,
                            titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { modelContext.delete(snippet) }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("\"\(snippet.title)\" wird unwiderruflich gelöscht.")
        }
    }

    // MARK: - Header

    private var headerBereich: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(snippet.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        TagPill(text: snippet.effectiveLanguageName, farbe: .blue)
                        if snippet.difficulty >= 1 && snippet.difficulty <= 3 {
                            HStack(spacing: 4) {
                                SchwierigkeitSterne(stufe: snippet.difficulty)
                                Text(schwierigkeitLabels[snippet.difficulty])
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(schwierigkeitFarbe.opacity(0.12))
                            .foregroundStyle(schwierigkeitFarbe)
                            .clipShape(Capsule())
                        }
                        if !snippet.topic.isEmpty {
                            TagPill(text: snippet.topic, farbe: .teal)
                        }
                    }
                }

                Spacer()

                Button {
                    snippet.isFavorite.toggle()
                } label: {
                    Image(systemName: snippet.isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(snippet.isFavorite ? .yellow : .secondary)
                        .symbolEffect(.bounce, value: snippet.isFavorite)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Code

    private var codeBereich: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(titel: "Code")
                Spacer()
                Button {
                    kopieren()
                } label: {
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

            CodeHighlightView(
                code: snippet.code,
                highlightName: snippet.effectiveHighlightName
            )
        }
    }

    // MARK: - Hilfs-Views

    @ViewBuilder
    private func infoBereich<Content: View>(titel: String, @ViewBuilder inhalt: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(titel: titel)
            inhalt()
        }
    }

    private var schwierigkeitFarbe: Color {
        switch snippet.difficulty {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .secondary
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
