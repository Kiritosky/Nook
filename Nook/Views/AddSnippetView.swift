//
//  AddSnippetView.swift
//  Nook
//

import SwiftUI
import SwiftData

struct AddSnippetView: View {
    var initialCode: String
    var initialLanguage: Language
    var initialTitle: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomLanguage.name) private var customLanguages: [CustomLanguage]
    @Query(sort: \Projekt.name) private var projekte: [Projekt]

    @State private var titel: String
    @State private var code: String
    @State private var spracheName: String
    @State private var thema = ""
    @State private var projektName = ""
    @State private var schwierigkeit = 1
    @State private var beschreibung = ""
    @State private var outputText = ""
    @State private var tagsText = ""
    @State private var templatePickerAnzeigen = false

    init(initialCode: String = "", initialLanguage: Language = .python, initialTitle: String = "") {
        self.initialCode     = initialCode
        self.initialLanguage = initialLanguage
        self.initialTitle    = initialTitle
        _titel      = State(initialValue: initialTitle)
        _code       = State(initialValue: "")
        _spracheName = State(initialValue: initialLanguage.rawValue)
    }

    private var kannSpeichern: Bool {
        !titel.trimmingCharacters(in: .whitespaces).isEmpty &&
        !code.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var gewaehlteFarbe: Color {
        Language(rawValue: spracheName)?.farbe ?? .indigo
    }

    private var gewaehltesSymbol: String {
        Language(rawValue: spracheName)?.symbolName
            ?? customLanguages.first { $0.name == spracheName }?.symbolName
            ?? "doc.text"
    }

    private var effectiveHighlightName: String {
        Language(rawValue: spracheName)?.highlightName
            ?? customLanguages.first { $0.name == spracheName }?.highlightName
            ?? "plaintext"
    }

    private var verfuegbareTemplates: [SnippetTemplate] {
        SnippetTemplate.fuer(spracheName: spracheName)
    }

    var body: some View {
        HStack(spacing: 0) {
            linkeMetadaten
                .frame(width: 310)
            Divider()
            rechterCodeEditor
        }
        .frame(minWidth: 860, minHeight: 560)
        .onAppear {
            if !initialCode.isEmpty { code = initialCode }
        }
    }

    // MARK: - Linke Spalte

    private var linkeMetadaten: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                FarbIcon(symbol: gewaehltesSymbol, farbe: gewaehlteFarbe, groesse: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Neues Snippet").font(.headline)
                    Text(spracheName).font(.caption).foregroundStyle(gewaehlteFarbe)
                }
                Spacer()
            }
            .padding(16)
            .background(gewaehlteFarbe.opacity(0.1))
            .animation(.easeInOut(duration: 0.2), value: spracheName)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    feldSektion("Titel") {
                        TextField("z.B. Binary Search in Python", text: $titel)
                            .textFieldStyle(.roundedBorder)
                    }

                    feldSektion("Sprache") {
                        ForEach(Language.gruppen, id: \.titel) { gruppe in
                            if gruppe.titel != Language.gruppen.first?.titel {
                                Divider().padding(.top, 4)
                            }
                            Text(LocalizedStringKey(gruppe.titel)).textCase(.uppercase)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.tertiary).tracking(0.5)
                                .padding(.top, 2)
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                                spacing: 6
                            ) {
                                ForEach(gruppe.sprachen, id: \.self) { lang in
                                    spracheButton(name: lang.rawValue, symbol: lang.symbolName, farbe: lang.farbe)
                                }
                            }
                        }
                        if !customLanguages.isEmpty {
                            Divider().padding(.top, 4)
                            Text("EIGENE")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.tertiary).tracking(0.5).padding(.top, 2)
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                                spacing: 6
                            ) {
                                ForEach(customLanguages) { lang in
                                    spracheButton(name: lang.name, symbol: lang.symbolName, farbe: .indigo)
                                }
                            }
                        }
                    }

                    feldSektion("Thema") {
                        TextField("z.B. Algorithmen, Netzwerk, UI", text: $thema)
                            .textFieldStyle(.roundedBorder)
                    }

                    feldSektion("Projekt") {
                        projektPicker
                    }

                    feldSektion("Schwierigkeit") {
                        HStack(spacing: 6) {
                            ForEach(1...3, id: \.self) { stufe in
                                Button { schwierigkeit = stufe } label: {
                                    VStack(spacing: 3) {
                                        SchwierigkeitSterne(stufe: stufe)
                                        Text(LocalizedStringKey(["", "Anfänger", "Mittel", "Profi"][stufe]))
                                            .font(.system(size: 9))
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .background(schwierigkeit == stufe ? gewaehlteFarbe.opacity(0.15) : Color.clear)
                                    .overlay(RoundedRectangle(cornerRadius: 7)
                                        .stroke(schwierigkeit == stufe
                                                ? gewaehlteFarbe.opacity(0.5)
                                                : Color.secondary.opacity(0.18), lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    feldSektion("Tags") {
                        TextField("array, sort, performance", text: $tagsText)
                            .textFieldStyle(.roundedBorder)
                        Text("Mehrere Tags mit Komma trennen")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Speichern") { speichern() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!kannSpeichern)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(12)
        }
    }

    // MARK: - Projekt-Picker

    private var projektPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button { projektName = "" } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 9))
                        Text("Keins")
                            .font(.caption)
                            .fontWeight(projektName.isEmpty ? .semibold : .regular)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(projektName.isEmpty
                                ? Color.secondary.opacity(0.2)
                                : Color.secondary.opacity(0.07))
                    .foregroundStyle(projektName.isEmpty ? Color.primary : Color.secondary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(
                        projektName.isEmpty ? Color.secondary.opacity(0.4) : Color.secondary.opacity(0.15),
                        lineWidth: projektName.isEmpty ? 1.5 : 0.5
                    ))
                }
                .buttonStyle(.plain)

                ForEach(projekte) { p in
                    ProjektPill(
                        name: p.name,
                        farbe: p.farbe,
                        symbol: p.symbolName,
                        aktiv: projektName == p.name
                    ) { projektName = p.name }
                }

                if projekte.isEmpty {
                    Text("Projekte in Einstellungen → Projekte anlegen")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .fixedSize()
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Rechte Spalte (Code)

    private var rechterCodeEditor: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Code").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)

                Spacer()

                // Template-Picker (nur wenn Templates vorhanden)
                if !verfuegbareTemplates.isEmpty {
                    Button {
                        templatePickerAnzeigen = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                            Text("Template")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $templatePickerAnzeigen, arrowEdge: .bottom) {
                        TemplatePickerView(
                            templates: verfuegbareTemplates,
                            spracheName: spracheName
                        ) { template in
                            code = template.code
                            templatePickerAnzeigen = false
                        }
                    }
                }

                if !code.isEmpty {
                    Text("\(code.components(separatedBy: "\n").count) Zeilen")
                        .font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Color.primary.opacity(0.03))

            Divider()

            // Nativer Code-Editor mit Live-Highlighting
            SyntaxTextEditor(text: $code, highlightName: effectiveHighlightName)

            Divider()

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: "text.alignleft").font(.caption2).foregroundStyle(.tertiary).padding(.top, 2)
                    TextField("Beschreibung (optional)", text: $beschreibung, axis: .vertical)
                        .textFieldStyle(.plain).font(.callout).lineLimit(2...4)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)

                Divider()

                HStack(alignment: .top) {
                    Image(systemName: "terminal").font(.caption2).foregroundStyle(.tertiary).padding(.top, 2)
                    TextField("Beispiel-Output (optional)", text: $outputText, axis: .vertical)
                        .textFieldStyle(.plain).font(.system(.caption, design: .monospaced)).lineLimit(2...3)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
            }
            .background(Color.primary.opacity(0.02))
        }
    }

    // MARK: - Hilfskomponenten

    @ViewBuilder
    private func feldSektion<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(label)).textCase(.uppercase)
                .font(.caption2).fontWeight(.semibold).foregroundStyle(.tertiary).tracking(0.5)
            content()
        }
    }

    @ViewBuilder
    private func spracheButton(name: String, symbol: String, farbe: Color) -> some View {
        let gewaehlt = spracheName == name
        Button { spracheName = name } label: {
            VStack(spacing: 4) {
                FarbIcon(symbol: symbol, farbe: gewaehlt ? farbe : .secondary.opacity(0.6), groesse: 28)
                Text(name).font(.system(size: 9)).lineLimit(1)
                    .foregroundStyle(gewaehlt ? farbe : Color.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 6)
            .background(gewaehlt ? farbe.opacity(0.12) : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(gewaehlt ? farbe.opacity(0.45) : Color.clear, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeInOut(duration: 0.15), value: gewaehlt)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Speichern

    private func speichern() {
        let tags = tagsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let builtIn = Language(rawValue: spracheName)
        let customHighlight = customLanguages.first { $0.name == spracheName }?.highlightName

        let snippet = Snippet(
            title: titel.trimmingCharacters(in: .whitespaces),
            code: code,
            language: builtIn ?? .other,
            topic: thema,
            project: projektName.isEmpty ? nil : projektName,
            difficulty: schwierigkeit,
            tags: tags,
            descriptionText: beschreibung.isEmpty ? nil : beschreibung,
            output: outputText.isEmpty ? nil : outputText,
            languageOverride: builtIn != nil ? nil : spracheName,
            customHighlightName: customHighlight
        )
        modelContext.insert(snippet)
        SpotlightManager.index(snippet)
        dismiss()
    }
}

// MARK: - Template Daten

struct SnippetTemplate: Identifiable {
    let id = UUID()
    let titel: String
    let code: String

    static func fuer(spracheName: String) -> [SnippetTemplate] {
        templates[spracheName] ?? []
    }

    private static let templates: [String: [SnippetTemplate]] = {
        func t(_ titel: String, _ code: String) -> SnippetTemplate { SnippetTemplate(titel: titel, code: code) }
        return [
            "Python": [
                t("Klasse", "class ClassName:\n    def __init__(self):\n        self.value = None\n\n    def method(self):\n        pass"),
                t("Funktion", "def function_name(param1, param2):\n    \"\"\"Docstring.\"\"\"\n    result = None\n    return result"),
                t("Decorator", "def decorator(func):\n    def wrapper(*args, **kwargs):\n        result = func(*args, **kwargs)\n        return result\n    return wrapper"),
                t("List Comprehension", "result = [item for item in iterable if condition]"),
            ],
            "Swift": [
                t("Struct", "struct ModelName {\n    let id: UUID\n    var name: String\n\n    init(name: String) {\n        self.id = UUID()\n        self.name = name\n    }\n}"),
                t("SwiftUI View", "struct MyView: View {\n    @State private var isActive = false\n\n    var body: some View {\n        VStack {\n            Text(\"Hello, World!\")\n        }\n    }\n}"),
                t("Async Funktion", "func fetchData() async throws -> Data {\n    let url = URL(string: \"https://api.example.com\")!\n    let (data, _) = try await URLSession.shared.data(from: url)\n    return data\n}"),
                t("Extension", "extension TypeName {\n    func method() -> ReturnType {\n        \n    }\n}"),
            ],
            "JavaScript": [
                t("Arrow Function", "const functionName = (param1, param2) => {\n    const result = param1 + param2;\n    return result;\n};"),
                t("Async/Await", "const fetchData = async (url) => {\n    try {\n        const response = await fetch(url);\n        const data = await response.json();\n        return data;\n    } catch (error) {\n        console.error('Error:', error);\n        throw error;\n    }\n};"),
                t("Klasse", "class ClassName {\n    constructor(param) {\n        this.param = param;\n    }\n\n    method() {\n        return this.param;\n    }\n}"),
            ],
            "TypeScript": [
                t("Interface + Funktion", "interface User {\n    id: number;\n    name: string;\n    email: string;\n}\n\nasync function getUser(id: number): Promise<User> {\n    const res = await fetch(`/api/users/${id}`);\n    return res.json();\n}"),
                t("Generic", "function identity<T>(arg: T): T {\n    return arg;\n}\n\nconst result = identity<string>('hello');"),
            ],
            "React": [
                t("Functional Component", "import { useState, useEffect } from 'react';\n\nexport default function ComponentName({ prop }) {\n    const [data, setData] = useState(null);\n\n    useEffect(() => {\n        // fetch data\n    }, []);\n\n    return (\n        <div className=\"container\">\n            <h1>{prop}</h1>\n        </div>\n    );\n}"),
                t("Custom Hook", "import { useState, useEffect } from 'react';\n\nexport function useData(url) {\n    const [data, setData] = useState(null);\n    const [loading, setLoading] = useState(true);\n    const [error, setError] = useState(null);\n\n    useEffect(() => {\n        fetch(url)\n            .then(res => res.json())\n            .then(setData)\n            .catch(setError)\n            .finally(() => setLoading(false));\n    }, [url]);\n\n    return { data, loading, error };\n}"),
            ],
            "SQL": [
                t("SELECT", "SELECT\n    column1,\n    column2,\n    COUNT(*) AS total\nFROM table_name\nWHERE condition = 'value'\nGROUP BY column1, column2\nORDER BY total DESC\nLIMIT 100;"),
                t("JOIN", "SELECT\n    a.id,\n    a.name,\n    b.value\nFROM table_a a\nINNER JOIN table_b b\n    ON a.id = b.a_id\nWHERE a.active = true\nORDER BY a.name;"),
                t("CREATE TABLE", "CREATE TABLE users (\n    id SERIAL PRIMARY KEY,\n    name VARCHAR(255) NOT NULL,\n    email VARCHAR(255) UNIQUE NOT NULL,\n    created_at TIMESTAMP DEFAULT NOW()\n);"),
            ],
            "Bash": [
                t("Script Header", "#!/bin/bash\nset -euo pipefail\n\nmain() {\n    local arg=\"${1:-}\"\n    echo \"Processing: $arg\"\n}\n\nmain \"$@\""),
                t("For Loop", "for item in \"${array[@]}\"; do\n    echo \"Processing: $item\"\ndone"),
                t("Funktion mit Check", "function process_file() {\n    local file=\"$1\"\n    if [[ ! -f \"$file\" ]]; then\n        echo \"Error: $file not found\" >&2\n        return 1\n    fi\n    echo \"Processing $file...\"\n}"),
            ],
            "Go": [
                t("HTTP Handler", "package main\n\nimport (\n    \"encoding/json\"\n    \"net/http\"\n)\n\nfunc handler(w http.ResponseWriter, r *http.Request) {\n    data := map[string]string{\"status\": \"ok\"}\n    w.Header().Set(\"Content-Type\", \"application/json\")\n    json.NewEncoder(w).Encode(data)\n}"),
                t("Goroutine + Channel", "func worker(jobs <-chan int, results chan<- int) {\n    for j := range jobs {\n        results <- j * 2\n    }\n}"),
            ],
            "Rust": [
                t("Struct + Impl", "struct Point {\n    x: f64,\n    y: f64,\n}\n\nimpl Point {\n    fn new(x: f64, y: f64) -> Self {\n        Point { x, y }\n    }\n\n    fn distance(&self, other: &Point) -> f64 {\n        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()\n    }\n}"),
                t("Result Handling", "fn parse_number(s: &str) -> Result<i32, String> {\n    s.trim().parse::<i32>().map_err(|e| format!(\"Parse error: {}\", e))\n}\n\nfn main() {\n    match parse_number(\"42\") {\n        Ok(n)  => println!(\"Got: {}\", n),\n        Err(e) => eprintln!(\"Error: {}\", e),\n    }\n}"),
            ],
            "Kotlin": [
                t("Data Class", "data class User(\n    val id: Long,\n    val name: String,\n    val email: String\n)\n\nfun main() {\n    val user = User(1L, \"Alice\", \"alice@example.com\")\n    println(user)\n}"),
                t("Extension Function", "fun String.isPalindrome(): Boolean {\n    val cleaned = this.lowercase().filter { it.isLetterOrDigit() }\n    return cleaned == cleaned.reversed()\n}"),
            ],
            "Java": [
                t("Klasse", "public class ClassName {\n    private String field;\n\n    public ClassName(String field) {\n        this.field = field;\n    }\n\n    public String getField() { return field; }\n    public void setField(String field) { this.field = field; }\n}"),
            ],
            "C": [
                t("Struct + Funktion", "#include <stdio.h>\n#include <stdlib.h>\n\ntypedef struct {\n    int x;\n    int y;\n} Point;\n\nPoint create_point(int x, int y) {\n    return (Point){ .x = x, .y = y };\n}\n\nint main() {\n    Point p = create_point(10, 20);\n    printf(\"(%d, %d)\\n\", p.x, p.y);\n    return 0;\n}"),
            ],
            "C++": [
                t("Klasse", "#include <iostream>\n#include <string>\n\nclass Animal {\nprivate:\n    std::string name;\npublic:\n    Animal(const std::string& name) : name(name) {}\n    virtual void speak() const {\n        std::cout << name << \" makes a sound\" << std::endl;\n    }\n    virtual ~Animal() = default;\n};"),
            ],
            "C#": [
                t("Klasse", "public class Service\n{\n    private readonly ILogger _logger;\n\n    public Service(ILogger logger)\n    {\n        _logger = logger;\n    }\n\n    public async Task<string> GetDataAsync(string id)\n    {\n        _logger.LogInformation($\"Getting data for {id}\");\n        return await FetchFromDatabase(id);\n    }\n}"),
            ],
            "Ruby": [
                t("Klasse", "class Animal\n  attr_reader :name\n\n  def initialize(name)\n    @name = name\n  end\n\n  def speak\n    \"#{name} says something\"\n  end\nend"),
            ],
            "PHP": [
                t("Klasse", "<?php\n\nclass UserRepository\n{\n    private PDO $db;\n\n    public function __construct(PDO $db)\n    {\n        $this->db = $db;\n    }\n\n    public function findById(int $id): ?array\n    {\n        $stmt = $this->db->prepare('SELECT * FROM users WHERE id = ?');\n        $stmt->execute([$id]);\n        return $stmt->fetch() ?: null;\n    }\n}"),
            ],
            "Dart": [
                t("StatefulWidget", "import 'package:flutter/material.dart';\n\nclass MyWidget extends StatefulWidget {\n  const MyWidget({super.key});\n\n  @override\n  State<MyWidget> createState() => _MyWidgetState();\n}\n\nclass _MyWidgetState extends State<MyWidget> {\n  @override\n  Widget build(BuildContext context) {\n    return const Placeholder();\n  }\n}"),
            ],
            "HTML": [
                t("Page Boilerplate", "<!DOCTYPE html>\n<html lang=\"de\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Titel</title>\n    <link rel=\"stylesheet\" href=\"style.css\">\n</head>\n<body>\n    <main>\n        <h1>Willkommen</h1>\n    </main>\n    <script src=\"app.js\"></script>\n</body>\n</html>"),
            ],
            "CSS": [
                t("Flexbox", ".container {\n    display: flex;\n    flex-direction: row;\n    align-items: center;\n    justify-content: space-between;\n    gap: 1rem;\n    padding: 1rem;\n}\n\n.item {\n    flex: 1;\n    min-width: 0;\n}"),
                t("CSS Variablen", ":root {\n    --color-primary: #0066cc;\n    --color-secondary: #6c757d;\n    --spacing-sm: 0.5rem;\n    --spacing-md: 1rem;\n    --spacing-lg: 2rem;\n    --border-radius: 8px;\n}"),
            ],
            "Markdown": [
                t("README", "# Projektname\n\n## Beschreibung\n\nKurze Beschreibung des Projekts.\n\n## Installation\n\n```bash\nnpm install\n```\n\n## Verwendung\n\n```bash\nnpm start\n```\n\n## Lizenz\n\nMIT"),
            ],
            "JSON": [
                t("API Response", "{\n    \"status\": \"success\",\n    \"data\": {\n        \"id\": 1,\n        \"name\": \"Example\",\n        \"items\": []\n    },\n    \"error\": null\n}"),
            ],
            "YAML": [
                t("Docker Compose", "version: '3.8'\n\nservices:\n  app:\n    build: .\n    ports:\n      - \"8080:8080\"\n    environment:\n      - NODE_ENV=production\n    depends_on:\n      - db\n\n  db:\n    image: postgres:15\n    environment:\n      POSTGRES_DB: myapp\n      POSTGRES_USER: user\n      POSTGRES_PASSWORD: secret"),
            ],
        ]
    }()
}

// MARK: - Template-Picker Popover

private struct TemplatePickerView: View {
    let templates: [SnippetTemplate]
    let spracheName: String
    let onSelect: (SnippetTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Templates – \(spracheName)")
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(templates) { template in
                        Button {
                            onSelect(template)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.text")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(template.titel)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.primary.opacity(0.001))
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: 240, height: min(CGFloat(templates.count) * 42 + 60, 320))
    }
}
