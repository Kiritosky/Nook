//
//  SettingsView.swift
//  Nook
//

import SwiftUI
import SwiftData
import ServiceManagement
import AppKit
import UniformTypeIdentifiers

// MARK: - Settings Container

enum SettingsSektion: String, Hashable, CaseIterable {
    case allgemein, erscheinungsbild, sprachen, projekte, daten

    var titel: String {
        switch self {
        case .allgemein:       return "Allgemein"
        case .erscheinungsbild: return "Erscheinungsbild"
        case .sprachen:        return "Sprachen"
        case .projekte:        return "Projekte"
        case .daten:           return "Daten"
        }
    }

    var symbol: String {
        switch self {
        case .allgemein:       return "gearshape.fill"
        case .erscheinungsbild: return "paintbrush.pointed.fill"
        case .sprachen:        return "chevron.left.forwardslash.chevron.right"
        case .projekte:        return "folder.fill"
        case .daten:           return "externaldrive.fill.badge.timemachine"
        }
    }

    var farbe: Color {
        switch self {
        case .allgemein:       return .secondary
        case .erscheinungsbild: return .indigo
        case .sprachen:        return .teal
        case .projekte:        return .orange
        case .daten:           return .green
        }
    }
}

struct SettingsView: View {
    @State private var auswahl: SettingsSektion? = .allgemein

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $auswahl) {
                ForEach(SettingsSektion.allCases, id: \.self) { sektion in
                    Label {
                        Text(sektion.titel)
                    } icon: {
                        Image(systemName: sektion.symbol)
                            .foregroundStyle(sektion.farbe)
                    }
                    .tag(sektion)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Einstellungen")
            .navigationSplitViewColumnWidth(160)
            // Kein Sidebar-Ausblenden-Knopf: Die Seitenleiste ist bei einem
            // Einstellungsfenster fest — der Toggle ließ oben nur einen
            // abgeschnitten wirkenden Leerraum zurück.
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                switch auswahl {
                case .allgemein:       GeneralSettingsView()
                case .erscheinungsbild: AppearanceSettingsView()
                case .sprachen:        LanguageSettingsView()
                case .projekte:        ProjektSettingsView()
                case .daten:           DataSettingsView()
                case nil:
                    ContentUnavailableView("Wähle eine Kategorie", systemImage: "gearshape")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 740, height: 520)
    }
}

// MARK: - Allgemein

struct GeneralSettingsView: View {
    @EnvironmentObject private var updater: UpdaterController
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @AppStorage("globalShortcut") private var globalShortcutRaw: String = StoredShortcut.defaultGlobal.rawValue
    @AppStorage("appSprache") private var appSpracheRaw: String = AppSprache.system.rawValue

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }
    private var buildString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }

    // Binding: konvertiert zwischen String (AppStorage) und StoredShortcut?
    private var globalShortcutBinding: Binding<StoredShortcut?> {
        Binding(
            get: { StoredShortcut(rawValue: globalShortcutRaw) },
            set: { globalShortcutRaw = $0?.rawValue ?? "" }
        )
    }

    private let inAppShortcuts: [(String, String)] = [
        ("⌘N",       "Neues Snippet erstellen"),
        ("⌘E",       "Snippet bearbeiten"),
        ("⌘⇧C",      "Code kopieren"),
        ("⌘,",       "Einstellungen öffnen"),
        ("?",        "Kürzel-Übersicht anzeigen"),
    ]

    var body: some View {
        Form {
            Section {
                Picker("Sprache der Oberfläche", selection: $appSpracheRaw) {
                    ForEach(AppSprache.allCases) { sprache in
                        Text(sprache.titel).tag(sprache.rawValue)
                    }
                }
                .onChange(of: appSpracheRaw) { _, neu in
                    let code = AppSprache(rawValue: neu)?.code
                    if let code { UserDefaults.standard.set([code], forKey: "AppleLanguages") }
                    else { UserDefaults.standard.removeObject(forKey: "AppleLanguages") }
                }
            } header: {
                Label("Sprache", systemImage: "globe")
            } footer: {
                Text("Manche Bereiche übernehmen die Sprache erst nach einem Neustart der App.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Toggle("Beim Anmelden starten", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue { try SMAppService.mainApp.register() }
                            else        { try SMAppService.mainApp.unregister() }
                        } catch { launchAtLogin = !newValue }
                    }
            } header: {
                Label("Start", systemImage: "power")
            } footer: {
                Text("Nook startet automatisch als Menüleisten-App, wenn du dich anmeldest.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            // MARK: Globaler Shortcut
            Section {
                LabeledContent("Nook öffnen") {
                    HStack(spacing: 10) {
                        ShortcutRecorder(shortcut: globalShortcutBinding)
                            .frame(width: 160, height: 26)

                        if globalShortcutRaw != StoredShortcut.defaultGlobal.rawValue {
                            Button("Zurücksetzen") {
                                globalShortcutRaw = StoredShortcut.defaultGlobal.rawValue
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Globaler Shortcut", systemImage: "keyboard.badge.ellipsis")
            } footer: {
                Text("Klicke auf das Feld und drücke eine Tastenkombination (mindestens ⌘, ⌥, ⌃ oder ⇧). Mit ⌫ wird das Kürzel gelöscht.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            // MARK: In-App Kürzel (Referenz)
            Section {
                ForEach(inAppShortcuts, id: \.0) { item in
                    LabeledContent(item.1) {
                        Text(item.0)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Label("In-App Kürzel", systemImage: "keyboard")
            } footer: {
                Text("Diese Kürzel folgen macOS-Konventionen und können nicht geändert werden.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                GitHubKontoView()
            } header: {
                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            } footer: {
                Text("Melde dich an, um Snippets als Gist zu veröffentlichen. Gists importieren geht unter Daten.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version") {
                    Text(versionString).foregroundStyle(.secondary)
                }
                LabeledContent("Build") {
                    Text(buildString).foregroundStyle(.secondary)
                }
                LabeledContent("Plattform") {
                    Text("macOS").foregroundStyle(.secondary)
                }
                Button {
                    updater.nachUpdatesSuchen()
                } label: {
                    Label("Nach Updates suchen …", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(!updater.kannPruefen)
            } header: {
                Label("Über Nook", systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Allgemein")
    }
}

// MARK: - Erscheinungsbild

struct AppearanceSettingsView: View {
    @AppStorage("syntaxTheme")     private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("codeFontSize")    private var codeFontSize: Double = 12.5
    @AppStorage("showCodePreview") private var showCodePreview: Bool = true
    @AppStorage("autoTheme")       private var autoTheme: Bool = false
    @AppStorage("autoThemeDark")   private var autoThemeDark: SyntaxTheme = .catppuccinMocha
    @AppStorage("autoThemeLight")  private var autoThemeLight: SyntaxTheme = .xcodeLight

    // Python-Beispielcode für die Live-Vorschau
    private let vorschauCode = """
def quicksort(arr: list) -> list:
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left  = [x for x in arr if x < pivot]
    mid   = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + mid + quicksort(right)

result = quicksort([3, 6, 8, 10, 1, 2, 1])
print(result)  # [1, 1, 2, 3, 6, 8, 10]
"""

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $syntaxTheme) {
                    ForEach(SyntaxTheme.allCases) { theme in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.hintergrundFarbe)
                                .frame(width: 20, height: 20)
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                            Text(theme.rawValue)
                        }.tag(theme)
                    }
                }
                .pickerStyle(.menu)

                // Live-Vorschau mit echtem Syntax Highlighting
                CodeHighlightView(code: vorschauCode, highlightName: "python")
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 0.5))
                    .animation(.easeInOut(duration: 0.25), value: syntaxTheme)

            } header: {
                Label("Syntax Highlighting", systemImage: "paintpalette")
            }

            Section {
                HStack(spacing: 12) {
                    Text("Schriftgröße")
                    Slider(value: $codeFontSize, in: 10...18, step: 0.5)
                        .frame(maxWidth: 200)
                    Text("\(codeFontSize, specifier: "%.1f") pt")
                        .monospacedDigit().foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }
                // Mini-Vorschau der Schriftgröße
                HStack {
                    Text("Vorschau:")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("let x = 42")
                        .font(.system(size: CGFloat(codeFontSize), design: .monospaced))
                        .foregroundStyle(.primary)
                }
            } header: {
                Label("Code-Schrift", systemImage: "textformat.size")
            }

            Section {
                Toggle("Automatisch mit System-Modus wechseln", isOn: $autoTheme)
                    .onChange(of: autoTheme) { _, on in
                        if !on { return }
                        // Sofort anwenden wenn aktiviert
                    }

                if autoTheme {
                    Picker("Helles Theme", selection: $autoThemeLight) {
                        ForEach(SyntaxTheme.allCases.filter { $0.isLight }) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    Picker("Dunkles Theme", selection: $autoThemeDark) {
                        ForEach(SyntaxTheme.allCases.filter { !$0.isLight }) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
            } header: {
                Label("Auto-Theme", systemImage: "circle.lefthalf.filled")
            } footer: {
                if autoTheme {
                    Text("Das Syntax-Theme wechselt automatisch mit dem macOS Dark/Light Mode.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle("Code-Vorschau in der Snippet-Liste anzeigen", isOn: $showCodePreview)
            } header: {
                Label("Snippet-Liste", systemImage: "list.bullet.rectangle")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Erscheinungsbild")
    }
}

// MARK: - Sprachen

struct LanguageSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomLanguage.name) private var customLanguages: [CustomLanguage]

    @State private var hinzufuegenAnzeigen = false
    @State private var neuName = ""
    @State private var neuHighlight = ""
    @State private var neuSymbol = "doc.text"

    private var kannSpeichern: Bool {
        !neuName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !neuHighlight.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(Language.gruppen, id: \.titel) { gruppe in
                    Section(gruppe.titel) {
                        ForEach(gruppe.sprachen, id: \.self) { lang in
                            HStack(spacing: 10) {
                                FarbIcon(symbol: lang.symbolName, farbe: lang.farbe, groesse: 22)
                                Text(lang.rawValue)
                                Spacer()
                                Text(lang.highlightName)
                                    .font(.caption).foregroundStyle(.tertiary)
                                    .fontDesign(.monospaced)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }

                Section("Eigene Sprachen") {
                    if customLanguages.isEmpty {
                        Text("Noch keine eigenen Sprachen.")
                            .foregroundStyle(.tertiary).font(.caption)
                    } else {
                        ForEach(customLanguages) { lang in
                            HStack(spacing: 10) {
                                FarbIcon(symbol: lang.symbolName, farbe: .indigo, groesse: 22)
                                Text(lang.name)
                                Spacer()
                                Text(lang.highlightName)
                                    .font(.caption).foregroundStyle(.secondary)
                                    .fontDesign(.monospaced)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                Button { modelContext.delete(lang) } label: {
                                    Image(systemName: "trash").font(.caption).foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain).help("Sprache löschen")
                            }
                        }
                    }

                    HinzufuegenZeile(titel: "Eigene Sprache hinzufügen") { hinzufuegenAnzeigen = true }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Sprachen")
        .sheet(isPresented: $hinzufuegenAnzeigen, onDismiss: { neuName = ""; neuHighlight = ""; neuSymbol = "doc.text" }) {
            VStack(spacing: 20) {
                HStack {
                    FarbIcon(symbol: neuSymbol, farbe: .indigo, groesse: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Neue Sprache").font(.headline)
                        Text(neuName.isEmpty ? "Name eingeben..." : neuName).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)

                Form {
                    TextField("Name (z.B. Elixir)", text: $neuName)
                    TextField("Highlight-ID (z.B. elixir)", text: $neuHighlight).fontDesign(.monospaced)
                    Picker("Symbol", selection: $neuSymbol) {
                        Label("Dokument",  systemImage: "doc.text").tag("doc.text")
                        Label("Code",      systemImage: "chevron.left.forwardslash.chevron.right").tag("chevron.left.forwardslash.chevron.right")
                        Label("Zahnrad",   systemImage: "gearshape").tag("gearshape")
                        Label("Datenbank", systemImage: "cylinder").tag("cylinder")
                        Label("Gehirn",    systemImage: "brain").tag("brain")
                        Label("Netz",      systemImage: "network").tag("network")
                        Label("Blitz",     systemImage: "bolt").tag("bolt")
                        Label("Terminal",  systemImage: "terminal").tag("terminal")
                    }
                }
                .formStyle(.grouped).frame(height: 220)

                HStack {
                    Button("Abbrechen") { hinzufuegenAnzeigen = false }
                    Spacer()
                    Button("Hinzufügen") {
                        let lang = CustomLanguage(
                            name: neuName.trimmingCharacters(in: .whitespaces),
                            highlightName: neuHighlight.trimmingCharacters(in: .whitespaces),
                            symbolName: neuSymbol
                        )
                        modelContext.insert(lang)
                        hinzufuegenAnzeigen = false
                    }
                    .buttonStyle(.borderedProminent).disabled(!kannSpeichern)
                }
            }
            .padding(20).frame(width: 400)
        }
    }
}

// MARK: - Projekte

struct ProjektSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Projekt.name) private var projekte: [Projekt]

    @State private var hinzufuegenAnzeigen = false
    @State private var neuName = ""
    @State private var neuSymbol = "folder.fill"
    @State private var neuColorHex = "5856D6"

    private let projektFarben = [
        "007AFF", "5856D6", "AF52DE", "FF2D55",
        "FF3B30", "FF6B35", "FF9500", "FFCC00",
        "34C759", "30B0C7", "5AC8FA", "A2845E"
    ]

    private let projektSymbole = [
        "folder.fill", "doc.text.fill", "chevron.left.forwardslash.chevron.right",
        "gearshape.fill", "star.fill", "heart.fill", "bookmark.fill",
        "house.fill", "building.2.fill", "briefcase.fill", "graduationcap.fill",
        "gamecontroller.fill", "iphone", "desktopcomputer", "cloud.fill",
        "bolt.fill", "brain.fill", "network", "terminal.fill", "cylinder.fill"
    ]

    private var kannSpeichern: Bool {
        !neuName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Group {
            if projekte.isEmpty {
                LeererZustand(
                    symbol: "folder.badge.plus",
                    titel: "Keine Projekte",
                    beschreibung: "Projekte helfen dir, zusammengehörige Snippets zu gruppieren.",
                    cta: "Erstes Projekt erstellen"
                ) { hinzufuegenAnzeigen = true }
            } else {
                List {
                    ForEach(projekte) { projekt in
                        HStack(spacing: 10) {
                            FarbIcon(symbol: projekt.symbolName, farbe: projekt.farbe, groesse: 26)
                            Text(projekt.name).fontWeight(.medium)
                            Spacer()
                            Button { modelContext.delete(projekt) } label: {
                                Image(systemName: "trash").font(.caption).foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain).help("Projekt löschen")
                        }
                        .padding(.vertical, 2)
                    }

                    HinzufuegenZeile(titel: "Projekt hinzufügen") { hinzufuegenAnzeigen = true }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Projekte")
        .sheet(isPresented: $hinzufuegenAnzeigen, onDismiss: resetFelder) {
            projektHinzufuegenSheet
        }
    }

    private var projektHinzufuegenSheet: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                FarbIcon(symbol: neuSymbol, farbe: Color(hex: neuColorHex), groesse: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(neuName.isEmpty ? "Projektname" : neuName)
                        .font(.headline)
                        .foregroundStyle(neuName.isEmpty ? Color.secondary : Color.primary)
                    Text("Neues Projekt")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(Color(hex: neuColorHex).opacity(0.1))
            .animation(.easeInOut(duration: 0.2), value: neuColorHex)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAME").font(.caption2).fontWeight(.semibold).foregroundStyle(.tertiary).tracking(0.5)
                        TextField("z.B. MyApp, Studium, Arbeit", text: $neuName)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("FARBE").font(.caption2).fontWeight(.semibold).foregroundStyle(.tertiary).tracking(0.5)
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 6), spacing: 8) {
                            ForEach(projektFarben, id: \.self) { hex in
                                Button { neuColorHex = hex } label: {
                                    ZStack {
                                        Circle().fill(Color(hex: hex)).frame(width: 28, height: 28)
                                        if neuColorHex == hex {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .frame(width: 28, height: 28)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("SYMBOL").font(.caption2).fontWeight(.semibold).foregroundStyle(.tertiary).tracking(0.5)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(projektSymbole, id: \.self) { symbol in
                                let aktiv = neuSymbol == symbol
                                Button { neuSymbol = symbol } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(aktiv ? Color.white : Color.secondary)
                                        .frame(width: 38, height: 38)
                                        .background(
                                            aktiv ? Color(hex: neuColorHex) : Color.secondary.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 9)
                                        )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.15), value: neuSymbol)
                                .animation(.easeInOut(duration: 0.2), value: neuColorHex)
                            }
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Button("Abbrechen") { hinzufuegenAnzeigen = false }
                Spacer()
                Button("Erstellen") {
                    let p = Projekt(
                        name: neuName.trimmingCharacters(in: .whitespaces),
                        symbolName: neuSymbol,
                        colorHex: neuColorHex
                    )
                    modelContext.insert(p)
                    hinzufuegenAnzeigen = false
                }
                .buttonStyle(.borderedProminent).disabled(!kannSpeichern)
            }
            .padding(12)
        }
        .frame(width: 400, height: 520)
    }

    private func resetFelder() {
        neuName = ""
        neuSymbol = "folder.fill"
        neuColorHex = "5856D6"
    }
}

// MARK: - „Hinzufügen"-Zeile (letzte Zeile einer Liste)

/// Dezente Aktionszeile am Ende einer Liste — ersetzt sowohl die frühere
/// Bodenleiste (die neben der Seitenleiste unsymmetrisch wirkte) als auch den
/// Toolbar-Knopf (der oben deplatziert war). Sitzt sauber in der Liste, sodass
/// alle Panes gleich groß bleiben.
struct HinzufuegenZeile: View {
    let titel: LocalizedStringKey
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
                Text(titel)
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Zentrierter Leer-Zustand (für List-Panes ohne Inhalt)

/// Elegant zentrierter Platzhalter mit direkter Handlungsaufforderung.
/// Füllt den ganzen Detailbereich – dadurch sitzt er wirklich mittig
/// (statt wie eine ContentUnavailableView oben in einer List zu „verrutschen").
struct LeererZustand: View {
    let symbol: String
    let titel: LocalizedStringKey
    let beschreibung: LocalizedStringKey
    let cta: LocalizedStringKey
    let aktion: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.tertiary)
            VStack(spacing: 6) {
                Text(titel)
                    .font(.title3).fontWeight(.semibold)
                Text(beschreibung)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: aktion) {
                Label(cta, systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 2)
        }
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Daten (Export / Import / Sicherung)

struct DataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Snippet> { $0.deletedAt == nil })
    private var aktiveSnippets: [Snippet]
    @Query private var alleSnippets: [Snippet]

    @State private var status: StatusMeldung?

    // Automatische Sicherung
    @AppStorage("autoBackupAktiv")        private var autoBackupAktiv = true
    @AppStorage("autoBackupIntervallTage") private var autoBackupIntervallTage = 1
    @AppStorage("autoBackupAnzahl")       private var autoBackupAnzahl = 10
    @State private var backups: [BackupManager.BackupDatei] = []
    @State private var wiederherstellenZiel: BackupManager.BackupDatei?

    // GitHub-Gist-Import
    @State private var gistURL = ""
    @State private var gistLäuft = false

    private struct StatusMeldung: Identifiable {
        let id = UUID()
        let text: String
        let fehler: Bool
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Snippets") {
                    Text("\(aktiveSnippets.count)").foregroundStyle(.secondary).monospacedDigit()
                }
                if let status {
                    Label(status.text, systemImage: status.fehler ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(status.fehler ? .orange : .green)
                }
            } header: {
                Label("Sammlung", systemImage: "square.stack.3d.up.fill")
            }

            // MARK: Automatische Sicherung
            Section {
                Toggle("Automatisch sichern", isOn: $autoBackupAktiv)

                if autoBackupAktiv {
                    Picker("Häufigkeit", selection: $autoBackupIntervallTage) {
                        Text("Bei jedem Start").tag(0)
                        Text("Täglich").tag(1)
                        Text("Wöchentlich").tag(7)
                    }
                    Stepper("\(autoBackupAnzahl) Sicherungen aufbewahren",
                            value: $autoBackupAnzahl, in: 1...50)
                }

                Button {
                    jetztSichern()
                } label: {
                    Label("Jetzt sichern", systemImage: "clock.arrow.circlepath")
                }
                .disabled(alleSnippets.isEmpty)

                Button {
                    if let ordner = try? BackupManager.backupOrdner() {
                        NSWorkspace.shared.open(ordner)
                    }
                } label: {
                    Label("Sicherungsordner öffnen", systemImage: "folder")
                }
                .disabled(backups.isEmpty)
            } header: {
                Label("Automatische Sicherung", systemImage: "externaldrive.badge.timemachine")
            } footer: {
                Text("Nook legt regelmäßig eine vollständige Sicherung im App-Ordner an — ganz ohne Zutun. Die ältesten werden automatisch entfernt.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if !backups.isEmpty {
                Section {
                    ForEach(backups) { b in
                        HStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(b.erstellt, format: .dateTime.day().month().year().hour().minute())
                                    .font(.callout)
                                Text(groesseText(b.groesse))
                                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                            }
                            Spacer()
                            Button("Wiederherstellen …") { wiederherstellenZiel = b }
                                .buttonStyle(.borderless).font(.callout)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Label("Vorhandene Sicherungen", systemImage: "clock.arrow.2.circlepath")
                } footer: {
                    Text("Wiederherstellen fügt fehlende Snippets aus der Sicherung hinzu — vorhandene bleiben unberührt.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    exportieren()
                } label: {
                    Label("Sammlung exportieren …", systemImage: "square.and.arrow.up")
                }
                .disabled(aktiveSnippets.isEmpty)
            } header: {
                Label("Export", systemImage: "arrow.up.doc")
            } footer: {
                Text("Speichert alle Snippets als lesbare JSON-Datei — deine Sicherung, jederzeit wieder importierbar.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Button {
                    importieren()
                } label: {
                    Label("Aus Datei importieren …", systemImage: "square.and.arrow.down")
                }
            } header: {
                Label("Import", systemImage: "arrow.down.doc")
            } footer: {
                Text("Fügt Snippets aus einer Nook-Backup-Datei hinzu. Bereits vorhandene Snippets werden übersprungen.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    TextField("Gist-URL oder -ID", text: $gistURL)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { gistImportieren() }
                    Button { gistImportieren() } label: {
                        if gistLäuft { ProgressView().controlSize(.small) }
                        else { Text("Importieren") }
                    }
                    .disabled(gistURL.trimmingCharacters(in: .whitespaces).isEmpty || gistLäuft)
                }
            } header: {
                Label("GitHub-Gist importieren", systemImage: "chevron.left.forwardslash.chevron.right")
            } footer: {
                Text("Importiert die Dateien eines öffentlichen Gists als neue Snippets. Für private Gists in Einstellungen → Allgemein bei GitHub anmelden.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Daten")
        .onAppear { backups = BackupManager.vorhandene() }
        .alert("Sicherung wiederherstellen?",
               isPresented: Binding(get: { wiederherstellenZiel != nil },
                                    set: { if !$0 { wiederherstellenZiel = nil } })) {
            Button("Abbrechen", role: .cancel) { wiederherstellenZiel = nil }
            Button("Wiederherstellen") {
                if let ziel = wiederherstellenZiel { wiederherstellen(ziel) }
            }
        } message: {
            Text("Fehlende Snippets aus dieser Sicherung werden wieder hinzugefügt. Bereits vorhandene bleiben unverändert.")
        }
    }

    // MARK: Aktionen

    private func jetztSichern() {
        do {
            let url = try BackupManager.sichern(context: modelContext)
            backups = BackupManager.vorhandene()
            status = .init(text: "Gesichert: \(url.lastPathComponent)", fehler: false)
        } catch {
            status = .init(text: "Sicherung fehlgeschlagen: \(error.localizedDescription)", fehler: true)
        }
    }

    private func wiederherstellen(_ b: BackupManager.BackupDatei) {
        wiederherstellenZiel = nil
        do {
            let r = try BackupManager.wiederherstellen(aus: b.url, context: modelContext)
            let teile = [
                r.neu > 0 ? "\(r.neu) wiederhergestellt" : nil,
                r.uebersprungen > 0 ? "\(r.uebersprungen) übersprungen" : nil
            ].compactMap { $0 }
            status = .init(text: teile.isEmpty ? "Nichts wiederherzustellen." : teile.joined(separator: ", ") + ".", fehler: false)
        } catch {
            status = .init(text: "Wiederherstellen fehlgeschlagen — ist es eine gültige Sicherung?", fehler: true)
        }
    }

    private func groesseText(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func exportieren() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Nook-Backup-\(datumsStempel()).json"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try SnippetImportExport.exportieren(aktiveSnippets)
            try data.write(to: url, options: .atomic)
            status = .init(text: "\(aktiveSnippets.count) Snippets exportiert.", fehler: false)
        } catch {
            status = .init(text: "Export fehlgeschlagen: \(error.localizedDescription)", fehler: true)
        }
    }

    private func importieren() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let ergebnis = try SnippetImportExport.importieren(data, context: modelContext, vorhandene: alleSnippets)
            let teile = [
                ergebnis.neu > 0 ? "\(ergebnis.neu) importiert" : nil,
                ergebnis.uebersprungen > 0 ? "\(ergebnis.uebersprungen) übersprungen" : nil
            ].compactMap { $0 }
            status = .init(text: teile.isEmpty ? "Keine neuen Snippets." : teile.joined(separator: ", ") + ".", fehler: false)
        } catch {
            status = .init(text: "Import fehlgeschlagen — ist es eine gültige Nook-Backup-Datei?", fehler: true)
        }
    }

    private func datumsStempel() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func gistImportieren() {
        guard let id = GitHubKonto.gistID(aus: gistURL) else {
            status = .init(text: "Ungültige Gist-URL oder -ID.", fehler: true); return
        }
        gistLäuft = true
        Task {
            defer { gistLäuft = false }
            do {
                let dateien = try await GitHubKonto.shared.importiere(gistID: id)
                for d in dateien {
                    let ext = (d.name as NSString).pathExtension
                    let titel = (d.name as NSString).deletingPathExtension
                    modelContext.insert(Snippet(
                        title: titel.isEmpty ? d.name : titel,
                        code: d.inhalt,
                        language: Language.fromExtension(ext)
                    ))
                }
                status = .init(text: "\(dateien.count) Datei(en) aus Gist importiert.", fehler: false)
                gistURL = ""
            } catch {
                status = .init(text: "Gist-Import fehlgeschlagen: \(error.localizedDescription)", fehler: true)
            }
        }
    }
}
