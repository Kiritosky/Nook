//
//  MenuBarView.swift
//  Nook
//

import SwiftUI
import SwiftData

enum MenuBarFilter: Equatable {
    case alle, favoriten, angeheftet
    case projekt(String)
}

struct MenuBarView: View {
    @Query(sort: \Snippet.createdAt, order: .reverse) private var snippets: [Snippet]
    @Query(sort: \Projekt.name) private var projekte: [Projekt]
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext

    @State private var suchtext = ""
    @State private var kopierteID: PersistentIdentifier? = nil
    @State private var expandedID: PersistentIdentifier? = nil
    @State private var filter: MenuBarFilter = .alle
    @State private var clipboardSnippetAnzeigen = false

    private var clipboardText: String? {
        let text = NSPasteboard.general.string(forType: .string)
        return (text?.isEmpty == false) ? text : nil
    }

    private var angezeigteSnippets: [Snippet] {
        var basis: [Snippet]
        switch filter {
        case .alle:
            basis = suchtext.isEmpty ? Array(snippets.prefix(12)) : snippets
        case .favoriten:
            basis = snippets.filter { $0.isFavorite }
        case .angeheftet:
            basis = snippets.filter { $0.isPinned }
        case .projekt(let p):
            basis = snippets.filter { $0.project == p }
        }

        guard !suchtext.isEmpty else { return basis }
        return basis.filter {
            $0.title.localizedCaseInsensitiveContains(suchtext) ||
            $0.topic.localizedCaseInsensitiveContains(suchtext) ||
            $0.effectiveLanguageName.localizedCaseInsensitiveContains(suchtext) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(suchtext)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Suchfeld
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary).font(.caption)
                TextField("Snippet suchen...", text: $suchtext)
                    .textFieldStyle(.plain)
                if !suchtext.isEmpty {
                    Button { suchtext = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)

            Divider()

            // Filter-Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    menuFilterChip(label: "Alle",      symbol: "square.stack.3d.up",  aktiv: filter == .alle)      { filter = .alle }
                    menuFilterChip(label: "Favoriten", symbol: "star.fill",            aktiv: filter == .favoriten) { filter = .favoriten }
                    menuFilterChip(label: "Angeheftet", symbol: "pin.fill",            aktiv: filter == .angeheftet) { filter = .angeheftet }

                    if !projekte.isEmpty {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 1, height: 12)
                            .padding(.horizontal, 2)

                        ForEach(projekte) { p in
                            menuFilterChip(
                                label: p.name,
                                farbe: p.farbe,
                                aktiv: filter == .projekt(p.name)
                            ) {
                                filter = filter == .projekt(p.name) ? .alle : .projekt(p.name)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
            }
            .background(Color.primary.opacity(0.03))

            Divider()

            // Snippet-Liste
            if angezeigteSnippets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: filterEmptyIcon)
                        .font(.largeTitle).foregroundStyle(.quaternary)
                    Text(filterEmptyText)
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(angezeigteSnippets) { snippet in
                            MenuBarZeile(
                                snippet: snippet,
                                istKopiert: kopierteID == snippet.persistentModelID,
                                istExpanded: expandedID == snippet.persistentModelID,
                                onKopieren: { kopieren(snippet) },
                                onToggle: {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                        expandedID = expandedID == snippet.persistentModelID
                                            ? nil : snippet.persistentModelID
                                    }
                                }
                            )

                            if snippet.persistentModelID != angezeigteSnippets.last?.persistentModelID {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                }
            }

            Divider()

            // Footer
            VStack(spacing: 0) {
                if let clip = clipboardText {
                    Button { clipboardSnippetAnzeigen = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard").frame(width: 20).foregroundStyle(.teal)
                            Text("Snippet aus Zwischenablage").font(.caption).lineLimit(1)
                            Spacer()
                            Text(clip.prefix(20) + (clip.count > 20 ? "…" : ""))
                                .font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }

                HStack(spacing: 0) {
                    Button {
                        openWindow(id: "hauptfenster")
                        NSApp.setActivationPolicy(.regular)
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "macwindow")
                            Text("Öffnen")
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).padding(.horizontal, 12).padding(.vertical, 8)

                    Spacer()
                    Text("\(snippets.count) Snippets").font(.caption2).foregroundStyle(.tertiary)
                    Spacer()

                    Button { NSApp.terminate(nil) } label: {
                        HStack(spacing: 5) { Text("Beenden"); Image(systemName: "power") }
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).padding(.horizontal, 12).padding(.vertical, 8)
                }
            }
        }
        .frame(width: 360, height: 460)
        .sheet(isPresented: $clipboardSnippetAnzeigen) {
            AddSnippetView(initialCode: clipboardText ?? "")
        }
    }

    // MARK: - Hilfscomponents

    @ViewBuilder
    private func menuFilterChip(
        label: String,
        symbol: String? = nil,
        farbe: Color = .accentColor,
        aktiv: Bool,
        aktion: @escaping () -> Void
    ) -> some View {
        Button(action: aktion) {
            HStack(spacing: 4) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 8, weight: .semibold))
                } else {
                    Circle().fill(farbe).frame(width: 6, height: 6)
                }
                Text(label).font(.system(size: 11, weight: aktiv ? .semibold : .regular))
            }
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(aktiv ? farbe.opacity(0.18) : Color.secondary.opacity(0.08))
            .foregroundStyle(aktiv ? farbe : Color.secondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(aktiv ? farbe.opacity(0.4) : Color.clear, lineWidth: 1))
            .animation(.easeInOut(duration: 0.15), value: aktiv)
        }
        .buttonStyle(.plain)
    }

    private var filterEmptyIcon: String {
        switch filter {
        case .alle:       return suchtext.isEmpty ? "curlybraces" : "magnifyingglass"
        case .favoriten:  return "star.slash"
        case .angeheftet: return "pin.slash"
        case .projekt:    return "folder"
        }
    }

    private var filterEmptyText: String {
        switch filter {
        case .alle:       return suchtext.isEmpty ? "Noch keine Snippets" : "Keine Treffer"
        case .favoriten:  return "Keine Favoriten"
        case .angeheftet: return "Keine angehefteten Snippets"
        case .projekt(let p): return "Keine Snippets in \"\(p)\""
        }
    }

    private func kopieren(_ snippet: Snippet) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)
        kopierteID = snippet.persistentModelID
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            kopierteID = nil
        }
    }
}

// MARK: - Menu Bar Zeile

struct MenuBarZeile: View {
    let snippet: Snippet
    let istKopiert: Bool
    let istExpanded: Bool
    let onKopieren: () -> Void
    let onToggle: () -> Void

    private var codePreview: String {
        snippet.code
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(5)
            .joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Haupt-Zeile
            HStack(spacing: 0) {
                // Expand-Button (tapper)
                Button(action: onToggle) {
                    HStack(spacing: 10) {
                        FarbIcon(symbol: snippet.language.symbolName,
                                 farbe: snippet.akzentFarbe, groesse: 26)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(snippet.title)
                                .font(.subheadline).fontWeight(.medium)
                                .lineLimit(1).foregroundStyle(.primary)
                            HStack(spacing: 4) {
                                Text(snippet.effectiveLanguageName)
                                    .font(.caption2).foregroundStyle(.secondary)
                                if let proj = snippet.project, !proj.isEmpty {
                                    Text("·").foregroundStyle(.quaternary).font(.caption2)
                                    Text(proj).font(.caption2).foregroundStyle(.tertiary)
                                }
                            }
                        }

                        Spacer()

                        Image(systemName: istExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.leading, 12).padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Copy-Button
                Button(action: onKopieren) {
                    Image(systemName: istKopiert ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(istKopiert ? .green : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: istKopiert)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Code-Vorschau (wenn ausgeklappt)
            if istExpanded && !codePreview.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text(codePreview)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(11)
                }
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
