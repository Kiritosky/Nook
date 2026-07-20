//
//  SnippetDetailView.swift
//  Nook
//

import SwiftUI

struct SnippetDetailView: View {
    @Bindable var snippet: Snippet

    private let schwierigkeitLabels = ["", "Anfänger", "Mittel", "Fortgeschritten"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Kopfbereich mit Titel, Tags und Favoriten-Button
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

                // Code-Block mit Kopieren-Button
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Code")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(snippet.code, forType: .string)
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(snippet.code)
                            .font(.system(.body, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
    }
}

// Wiederverwendbare Tag-Pille (wird auch in SnippetListView genutzt)
struct TagPill: View {
    let text: String
    let farbe: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(farbe.opacity(0.15))
            .foregroundStyle(farbe)
            .clipShape(Capsule())
    }
}
