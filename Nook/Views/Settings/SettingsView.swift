//
//  SettingsView.swift
//  Nook
//

import SwiftUI
import SwiftData
import ServiceManagement

// MARK: - Settings Container

enum SettingsSektion: String, Hashable, CaseIterable {
    case allgemein, erscheinungsbild, sprachen, projekte

    var titel: String {
        switch self {
        case .allgemein:       return "Allgemein"
        case .erscheinungsbild: return "Erscheinungsbild"
        case .sprachen:        return "Sprachen"
        case .projekte:        return "Projekte"
        }
    }

    var symbol: String {
        switch self {
        case .allgemein:       return "gearshape.fill"
        case .erscheinungsbild: return "paintbrush.pointed.fill"
        case .sprachen:        return "chevron.left.forwardslash.chevron.right"
        case .projekte:        return "folder.fill"
        }
    }

    var farbe: Color {
        switch self {
        case .allgemein:       return .secondary
        case .erscheinungsbild: return .indigo
        case .sprachen:        return .teal
        case .projekte:        return .orange
        }
    }
}

struct SettingsView: View {
    @State private var auswahl: SettingsSektion? = .erscheinungsbild

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
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            Group {
                switch auswahl {
                case .allgemein:       GeneralSettingsView()
                case .erscheinungsbild: AppearanceSettingsView()
                case .sprachen:        LanguageSettingsView()
                case .projekte:        ProjektSettingsView()
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
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }
    private var buildString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }

    var body: some View {
        Form {
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

            Section {
                LabeledContent("Version") {
                    Text(versionString)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Build") {
                    Text(buildString)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Plattform") {
                    Text("macOS")
                        .foregroundStyle(.secondary)
                }
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
                }
            }

            Divider()

            HStack {
                Button { hinzufuegenAnzeigen = true } label: {
                    Label("Sprache hinzufügen", systemImage: "plus")
                }.buttonStyle(.borderedProminent)
                Spacer()
                Text("\(customLanguages.count) eigene \(customLanguages.count == 1 ? "Sprache" : "Sprachen")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(12)
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
        VStack(spacing: 0) {
            List {
                if projekte.isEmpty {
                    ContentUnavailableView(
                        "Keine Projekte",
                        systemImage: "folder",
                        description: Text("Erstelle dein erstes Projekt um Snippets zu organisieren.")
                    )
                } else {
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
                }
            }

            Divider()

            HStack {
                Button { hinzufuegenAnzeigen = true } label: {
                    Label("Projekt hinzufügen", systemImage: "plus")
                }.buttonStyle(.borderedProminent)
                Spacer()
                Text("\(projekte.count) \(projekte.count == 1 ? "Projekt" : "Projekte")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(12)
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
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 6), count: 5), spacing: 6) {
                            ForEach(projektSymbole, id: \.self) { symbol in
                                Button { neuSymbol = symbol } label: {
                                    FarbIcon(
                                        symbol: symbol,
                                        farbe: neuSymbol == symbol ? Color(hex: neuColorHex) : .secondary.opacity(0.5),
                                        groesse: 36
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 36 * 0.26)
                                            .stroke(neuSymbol == symbol ? Color(hex: neuColorHex).opacity(0.6) : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.15), value: neuSymbol)
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
