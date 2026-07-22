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
        }
        .frame(width: 560, height: 440)
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
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            } header: {
                Text("Start")
            } footer: {
                Text("Nook startet automatisch als Menüleisten-App, wenn du dich anmeldest.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–")
            } header: {
                Text("Über Nook")
            }
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                                )
                            Text(theme.rawValue)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.menu)

                // Theme-Vorschau
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
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
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
                            Text(lang.rawValue)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(lang.highlightName)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .fontDesign(.monospaced)
                        }
                    }
                }

                Section("Eigene Sprachen") {
                    if customLanguages.isEmpty {
                        Text("Noch keine eigenen Sprachen.")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    } else {
                        ForEach(customLanguages) { lang in
                            HStack {
                                FarbIcon(symbol: lang.symbolName, farbe: .indigo, groesse: 22)
                                Text(lang.name)
                                Spacer()
                                Text(lang.highlightName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fontDesign(.monospaced)
                                Button {
                                    modelContext.delete(lang)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                                .help("Sprache löschen")
                            }
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    hinzufuegenAnzeigen = true
                } label: {
                    Label("Sprache hinzufügen", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Text("\(customLanguages.count) eigene \(customLanguages.count == 1 ? "Sprache" : "Sprachen")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .sheet(isPresented: $hinzufuegenAnzeigen, onDismiss: resetFelder) {
            VStack(spacing: 20) {
                HStack {
                    FarbIcon(symbol: neuSymbol, farbe: .indigo, groesse: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Neue Sprache")
                            .font(.headline)
                        Text(neuName.isEmpty ? "Name eingeben..." : neuName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)

                Form {
                    TextField("Name (z.B. Rust)", text: $neuName)
                    TextField("Highlight.js ID (z.B. rust)", text: $neuHighlight)
                        .fontDesign(.monospaced)

                    Picker("Symbol", selection: $neuSymbol) {
                        Label("Dokument", systemImage: "doc.text").tag("doc.text")
                        Label("Code", systemImage: "chevron.left.forwardslash.chevron.right").tag("chevron.left.forwardslash.chevron.right")
                        Label("Zahnrad", systemImage: "gearshape").tag("gearshape")
                        Label("Datenbank", systemImage: "cylinder").tag("cylinder")
                        Label("Gehirn", systemImage: "brain").tag("brain")
                        Label("Netz", systemImage: "network").tag("network")
                        Label("Blitz", systemImage: "bolt").tag("bolt")
                        Label("Terminal", systemImage: "terminal").tag("terminal")
                    }
                }
                .formStyle(.grouped)
                .frame(height: 220)

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
                    .buttonStyle(.borderedProminent)
                    .disabled(!kannSpeichern)
                }
            }
            .padding(20)
            .frame(width: 400)
        }
    }

    private func resetFelder() {
        neuName = ""
        neuHighlight = ""
        neuSymbol = "doc.text"
    }
}
