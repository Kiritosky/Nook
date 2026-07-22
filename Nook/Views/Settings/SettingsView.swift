//
//  SettingsView.swift
//  Nook
//

import SwiftUI
import SwiftData
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Allgemein", systemImage: "gearshape") }
            AppearanceSettingsView()
                .tabItem { Label("Erscheinungsbild", systemImage: "paintbrush") }
            LanguageSettingsView()
                .tabItem { Label("Sprachen", systemImage: "chevron.left.forwardslash.chevron.right") }
            ProjektSettingsView()
                .tabItem { Label("Projekte", systemImage: "folder.fill") }
        }
        .frame(width: 580, height: 460)
    }
}

// MARK: - Allgemein

struct GeneralSettingsView: View {
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

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
            } header: { Text("Start") } footer: {
                Text("Nook startet automatisch als Menüleisten-App, wenn du dich anmeldest.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                LabeledContent("Build",   value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–")
            } header: { Text("Über Nook") }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Erscheinungsbild

struct AppearanceSettingsView: View {
    @AppStorage("syntaxTheme")     private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("codeFontSize")    private var codeFontSize: Double = 12.5
    @AppStorage("showCodePreview") private var showCodePreview: Bool = true

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $syntaxTheme) {
                    ForEach(SyntaxTheme.allCases) { theme in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.hintergrundFarbe)
                                .frame(width: 18, height: 18)
                                .overlay(RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                            Text(theme.rawValue)
                        }.tag(theme)
                    }
                }
                .pickerStyle(.menu)

                RoundedRectangle(cornerRadius: 8)
                    .fill(syntaxTheme.hintergrundFarbe)
                    .frame(height: 68)
                    .overlay(alignment: .leading) {
                        Text("func greet() {\n    print(\"Hallo, Nook!\")\n}")
                            .font(.system(size: codeFontSize, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(10)
                    }
                    .animation(.easeInOut(duration: 0.2), value: syntaxTheme)
            } header: { Text("Syntax Highlighting") }

            Section {
                HStack {
                    Text("Schriftgröße")
                    Slider(value: $codeFontSize, in: 10...18, step: 0.5)
                    Text("\(codeFontSize, specifier: "%.1f") pt")
                        .monospacedDigit().foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
                }
            } header: { Text("Code-Schrift") }

            Section {
                Toggle("Code-Vorschau in der Snippet-Liste anzeigen", isOn: $showCodePreview)
            } header: { Text("Liste") }
        }
        .formStyle(.grouped)
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
                Section("Eingebaut (nicht löschbar)") {
                    ForEach(Language.allCases, id: \.self) { lang in
                        HStack {
                            FarbIcon(symbol: lang.symbolName, farbe: lang.farbe, groesse: 22)
                            Text(lang.rawValue).foregroundStyle(.secondary)
                            Spacer()
                            Text(lang.highlightName).font(.caption).foregroundStyle(.tertiary).fontDesign(.monospaced)
                        }
                    }
                }
                Section("Eigene Sprachen") {
                    if customLanguages.isEmpty {
                        Text("Noch keine eigenen Sprachen.").foregroundStyle(.tertiary).font(.caption)
                    } else {
                        ForEach(customLanguages) { lang in
                            HStack {
                                FarbIcon(symbol: lang.symbolName, farbe: .indigo, groesse: 22)
                                Text(lang.name)
                                Spacer()
                                Text(lang.highlightName).font(.caption).foregroundStyle(.secondary).fontDesign(.monospaced)
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
                    TextField("Name (z.B. Rust)", text: $neuName)
                    TextField("Highlight.js ID (z.B. rust)", text: $neuHighlight).fontDesign(.monospaced)
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
        .sheet(isPresented: $hinzufuegenAnzeigen, onDismiss: resetFelder) {
            projektHinzufuegenSheet
        }
    }

    private var projektHinzufuegenSheet: some View {
        VStack(spacing: 0) {
            // Vorschau-Header
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
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAME").font(.caption2).fontWeight(.semibold).foregroundStyle(.tertiary).tracking(0.5)
                        TextField("z.B. MyApp, Studium, Arbeit", text: $neuName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Farbe
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

                    // Symbol
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
