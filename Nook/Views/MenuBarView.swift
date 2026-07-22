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
    @Environment(\.openSettings) private var openSettings

    @State private var suchtext = ""
    @State private var kopierteID: PersistentIdentifier? = nil
    @State private var expandedID: PersistentIdentifier? = nil
    @State private var filter: MenuBarFilter = .alle

    // Clipboard-Code wird über AppStorage an ContentView übergeben (Sheet kann
    // nicht zuverlässig aus MenuBarExtra geöffnet werden)
    @AppStorage("pendingClipboardCode") private var pendingClipboardCode: String = ""

    private var clipboardText: String? {
        let text = NSPasteboard.general.string(forType: .string)
        guard let text, !text.isEmpty else { return nil }
        // Nur sinnvollen Code-Text akzeptieren (nicht einzelne Wörter etc.)
        return text.count > 3 ? text : nil
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

            // MARK: Suchfeld
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

            // MARK: Filter-Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    filterPill(label: "Alle",       icon: "tray.full",    aktiv: filter == .alle)      { filter = .alle }
                    filterPill(label: "Favoriten",  icon: "star.fill",    aktiv: filter == .favoriten) { filter = .favoriten }
                    filterPill(label: "Angeheftet", icon: "pin.fill",     aktiv: filter == .angeheftet) { filter = .angeheftet }

                    if !projekte.isEmpty {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: 1, height: 14)
                            .padding(.horizontal, 3)

                        ForEach(projekte) { p in
                            filterPill(
                                label: p.name,
                                farbe: p.farbe,
                                aktiv: filter == .projekt(p.name)
                            ) {
                                filter = filter == .projekt(p.name) ? .alle : .projekt(p.name)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
            }
            .background(Color.primary.opacity(0.025))

            Divider()

            // MARK: Snippet-Liste
            if angezeigteSnippets.isEmpty {
                emptyState
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
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                        expandedID = expandedID == snippet.persistentModelID
                                            ? nil : snippet.persistentModelID
                                    }
                                }
                            )
                            if snippet.persistentModelID != angezeigteSnippets.last?.persistentModelID {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }
                }
            }

            Divider()

            // MARK: Footer
            VStack(spacing: 0) {
                // Clipboard-Aktion
                if let clip = clipboardText {
                    Button {
                        pendingClipboardCode = clip
                        bringHauptfensterInVordergrund()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard")
                                .frame(width: 22).foregroundStyle(.teal)
                            Text("Snippet aus Zwischenablage")
                                .font(.caption).lineLimit(1)
                            Spacer()
                            Text(clip.prefix(18) + (clip.count > 18 ? "…" : ""))
                                .font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }

                // Öffnen / Zähler / Einstellungen / Beenden
                HStack(spacing: 0) {
                    Button {
                        bringHauptfensterInVordergrund()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "macwindow")
                            Text("Öffnen")
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).padding(.horizontal, 12).padding(.vertical, 8)

                    Spacer()
                    Text("\(snippets.count) Snippet\(snippets.count == 1 ? "" : "s")")
                        .font(.caption2).foregroundStyle(.tertiary)
                    Spacer()

                    // Einstellungen öffnen
                    Button {
                        NSApp.setActivationPolicy(.regular)
                        openSettings()
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .help("Einstellungen")

                    Button { NSApp.terminate(nil) } label: {
                        HStack(spacing: 5) { Text("Beenden"); Image(systemName: "power") }
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).padding(.horizontal, 12).padding(.vertical, 8)
                }
            }
        }
        .frame(width: 360, height: 460)
    }

    // MARK: - Filter-Pill

    @ViewBuilder
    private func filterPill(
        label: String,
        icon: String? = nil,
        farbe: Color = .accentColor,
        aktiv: Bool,
        aktion: @escaping () -> Void
    ) -> some View {
        Button(action: aktion) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .semibold))
                } else {
                    Circle().fill(farbe).frame(width: 7, height: 7)
                }
                Text(label)
                    .font(.system(size: 11, weight: aktiv ? .semibold : .regular))
                    .lineLimit(1)
            }
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(aktiv ? farbe.opacity(0.15) : Color.secondary.opacity(0.07))
            .foregroundStyle(aktiv ? farbe : Color.secondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(aktiv ? farbe.opacity(0.4) : Color.clear, lineWidth: 1))
            .animation(.easeInOut(duration: 0.15), value: aktiv)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: filterEmptyIcon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.quaternary)
            Text(filterEmptyText)
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
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
        case .alle:               return suchtext.isEmpty ? "Noch keine Snippets" : "Keine Treffer für \"\(suchtext)\""
        case .favoriten:          return "Keine Favoriten vorhanden"
        case .angeheftet:         return "Keine angehefteten Snippets"
        case .projekt(let p):     return "Keine Snippets in \"\(p)\""
        }
    }

    // Bestehendes Hauptfenster in den Vordergrund holen statt neues zu öffnen.
    // openWindow() erzeugt immer eine neue WindowGroup-Instanz – das wollen wir vermeiden.
    private func bringHauptfensterInVordergrund() {
        NSApp.setActivationPolicy(.regular)
        if let fenster = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) {
            fenster.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "hauptfenster")
        }
        NSApp.activate(ignoringOtherApps: true)
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
            HStack(spacing: 0) {
                // Zeilen-Body → Toggle
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
                                    Text(proj).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                                }
                            }
                        }

                        Spacer(minLength: 4)

                        Image(systemName: istExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.quaternary)
                    }
                    .padding(.leading, 12).padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Copy-Button → separat
                Button(action: onKopieren) {
                    Image(systemName: istKopiert ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(istKopiert ? .green : .secondary)
                        .animation(.easeInOut(duration: 0.15), value: istKopiert)
                        .frame(width: 38, height: 46)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Code-Vorschau (aufgeklappt)
            if istExpanded && !codePreview.isEmpty {
                Text(codePreview)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Color.black.opacity(0.55))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
