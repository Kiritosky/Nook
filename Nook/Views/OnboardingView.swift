//
//  OnboardingView.swift
//  Nook
//
//  Mehrstufiger Erststart-Assistent: Willkommen → Sprache → Theme → Shortcut →
//  Fertig. Zweisprachig (DE/EN) – die Sprachwahl schaltet den Assistenten live um.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("onboardingGesehen") private var onboardingGesehen = false
    @AppStorage("appSprache")        private var appSpracheRaw = AppSprache.system.rawValue
    @AppStorage("syntaxTheme")       private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("globalShortcut")    private var globalShortcutRaw = StoredShortcut.defaultGlobal.rawValue

    @State private var schritt = 0
    @State private var beispieleGewuenscht = true

    private let anzahlSchritte = 5

    // MARK: Sprache

    private var istEnglisch: Bool {
        switch appSpracheRaw {
        case AppSprache.deutsch.rawValue:  return false
        case AppSprache.englisch.rawValue: return true
        default: return (Locale.preferredLanguages.first ?? "de").hasPrefix("en")
        }
    }
    private func t(_ de: String, _ en: String) -> String { istEnglisch ? en : de }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            fortschritt
                .padding(.top, 22).padding(.bottom, 6)

            Group {
                switch schritt {
                case 0: willkommen
                case 1: spracheSchritt
                case 2: themeSchritt
                case 3: shortcutSchritt
                default: fertigSchritt
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)))
            .id(schritt)

            Divider()
            fussleiste
                .padding(.horizontal, 32).padding(.vertical, 16)
        }
        .frame(width: 540, height: 660)
        .interactiveDismissDisabled()
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: schritt)
    }

    // MARK: Fortschritt

    private var fortschritt: some View {
        HStack(spacing: 7) {
            ForEach(0..<anzahlSchritte, id: \.self) { i in
                Capsule()
                    .fill(i == schritt ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: i == schritt ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.3), value: schritt)
            }
        }
    }

    // MARK: Fußleiste

    private var fussleiste: some View {
        HStack {
            if schritt > 0 {
                Button(t("Zurück", "Back")) { schritt -= 1 }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            Spacer()
            if schritt < anzahlSchritte - 1 {
                Button(t("Weiter", "Continue")) { schritt += 1 }
                    .controlSize(.large).buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button(t("Los geht’s", "Get started")) { fertig() }
                    .controlSize(.large).buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Schritt 0 · Willkommen

    private var willkommen: some View {
        VStack(spacing: 14) {
            Spacer()
            appMarke
            Text(t("Willkommen bei Nook", "Welcome to Nook"))
                .font(.system(size: 27, weight: .bold))
            Text(t("Dein ruhiger, privater Code-Wissensspeicher.",
                   "Your calm, private home for code snippets."))
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                merkmal("square.stack.3d.up.fill", .blue,
                        t("Sammeln & ordnen", "Collect & organize"),
                        t("Mit Sprache, Projekt, Thema und Tags.",
                          "By language, project, topic and tags."))
                merkmal("sparkle.magnifyingglass", .purple,
                        t("Blitzschnell finden", "Find in a flash"),
                        t("Volltext-Suche in der App und über Spotlight.",
                          "Full-text search in-app and via Spotlight."))
                merkmal("chevron.left.forwardslash.chevron.right", .orange,
                        t("Schön lesbar", "Beautifully readable"),
                        t("Live Syntax-Highlighting in 24 Sprachen.",
                          "Live syntax highlighting for 24 languages."))
            }
            .padding(.top, 10).padding(.horizontal, 44)
            Spacer()
        }
    }

    // MARK: - Schritt 1 · Sprache

    private var spracheSchritt: some View {
        VStack(spacing: 16) {
            Spacer()
            schrittKopf("globe", .teal,
                        t("Sprache", "Language"),
                        t("In welcher Sprache möchtest du Nook nutzen?",
                          "Which language should Nook use?"))
            HStack(spacing: 14) {
                sprachKachel(titel: "Deutsch", flagge: "🇩🇪", wert: .deutsch)
                sprachKachel(titel: "English", flagge: "🇬🇧", wert: .englisch)
            }
            .padding(.horizontal, 44).padding(.top, 8)
            Text(t("Kann später in den Einstellungen geändert werden.",
                   "You can change this later in Settings."))
                .font(.caption).foregroundStyle(.tertiary)
            Spacer()
        }
    }

    private func sprachKachel(titel: String, flagge: String, wert: AppSprache) -> some View {
        let gewaehlt = appSpracheRaw == wert.rawValue
        return Button {
            appSpracheRaw = wert.rawValue
            UserDefaults.standard.set([wert.code ?? "de"], forKey: "AppleLanguages")
        } label: {
            VStack(spacing: 10) {
                Text(flagge).font(.system(size: 40))
                Text(titel).font(.headline)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 26)
            .background(gewaehlt ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(gewaehlt ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: gewaehlt ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schritt 2 · Theme

    private var themeSchritt: some View {
        VStack(spacing: 16) {
            schrittKopf("paintpalette.fill", .indigo,
                        t("Farb-Thema", "Color theme"),
                        t("Wie soll dein Code aussehen?", "How should your code look?"))
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    ForEach(SyntaxTheme.allCases) { thema in
                        themeKachel(thema)
                    }
                }
                .padding(.horizontal, 32).padding(.bottom, 8)
            }
        }
        .padding(.top, 18)
    }

    private func themeKachel(_ thema: SyntaxTheme) -> some View {
        let gewaehlt = syntaxTheme == thema
        let code = "def gruss(name):\n    return f\"Hi {name}\""
        return Button { syntaxTheme = thema } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(SyntaxHighlighter.highlight(code: code, language: "python",
                                                 theme: thema, fontSize: 11))
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(thema.hintergrundFarbe, in: RoundedRectangle(cornerRadius: 8))
                HStack(spacing: 6) {
                    Text(thema.rawValue).font(.caption).fontWeight(.medium)
                    Spacer()
                    if gewaehlt {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                    }
                }
            }
            .padding(8)
            .background(gewaehlt ? Color.accentColor.opacity(0.10) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(gewaehlt ? Color.accentColor : Color.secondary.opacity(0.15),
                        lineWidth: gewaehlt ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schritt 3 · Shortcut

    private var shortcutSchritt: some View {
        VStack(spacing: 16) {
            Spacer()
            schrittKopf("keyboard.badge.ellipsis", .pink,
                        t("Globaler Shortcut", "Global shortcut"),
                        t("Nook von überall mit einem Tastenkürzel öffnen.",
                          "Open Nook from anywhere with a keyboard shortcut."))
            VStack(spacing: 10) {
                ShortcutRecorder(shortcut: shortcutBinding)
                    .frame(width: 200, height: 34)
                if globalShortcutRaw != StoredShortcut.defaultGlobal.rawValue {
                    Button(t("Auf Standard zurücksetzen", "Reset to default")) {
                        globalShortcutRaw = StoredShortcut.defaultGlobal.rawValue
                    }
                    .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.top, 6)
            Text(t("Klicke ins Feld und drücke eine Kombination (mind. ⌘, ⌥, ⌃ oder ⇧).",
                   "Click the field and press a combination (at least ⌘, ⌥, ⌃ or ⇧)."))
                .font(.caption).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center).padding(.horizontal, 44)
            Spacer()
        }
    }

    private var shortcutBinding: Binding<StoredShortcut?> {
        Binding(
            get: { StoredShortcut(rawValue: globalShortcutRaw) },
            set: { globalShortcutRaw = $0?.rawValue ?? "" }
        )
    }

    // MARK: - Schritt 4 · Fertig

    private var fertigSchritt: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color.green.opacity(0.15)).frame(width: 84, height: 84)
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .bold)).foregroundStyle(.green)
            }
            Text(t("Alles bereit!", "You’re all set!"))
                .font(.system(size: 24, weight: .bold))
            Text(t("Lege dein erstes Snippet mit ⌘N an — oder starte mit ein paar Beispielen.",
                   "Create your first snippet with ⌘N — or start with a few examples."))
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)

            Toggle(isOn: $beispieleGewuenscht) {
                Text(t("Beispiel-Snippets hinzufügen", "Add example snippets"))
            }
            .toggleStyle(.checkbox)
            .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Bausteine

    private var appMarke: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 76, height: 76)
                .shadow(color: Color.accentColor.opacity(0.35), radius: 14, y: 6)
            Image(systemName: "curlybraces")
                .font(.system(size: 34, weight: .semibold)).foregroundStyle(.white)
        }
    }

    private func schrittKopf(_ symbol: String, _ farbe: Color, _ titel: String, _ text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .medium)).foregroundStyle(farbe)
                .frame(width: 60, height: 60)
                .background(farbe.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
            Text(titel).font(.system(size: 22, weight: .bold))
            Text(text).font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }

    private func merkmal(_ symbol: String, _ farbe: Color, _ titel: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium)).foregroundStyle(farbe)
                .frame(width: 32, height: 32)
                .background(farbe.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.headline)
                Text(text).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Abschluss

    private func fertig() {
        if beispieleGewuenscht {
            for snippet in OnboardingView.beispielSnippets() {
                modelContext.insert(snippet)
                SpotlightManager.index(snippet)
            }
        }
        onboardingGesehen = true
        dismiss()
    }

    // MARK: - Beispiel-Daten

    static func beispielSnippets() -> [Snippet] {
        [
            Snippet(
                title: "Debounce (JavaScript)",
                code: """
                function debounce(fn, delay = 300) {
                  let t;
                  return (...args) => {
                    clearTimeout(t);
                    t = setTimeout(() => fn(...args), delay);
                  };
                }
                """,
                language: .javascript, topic: "Utilities",
                difficulty: 2, tags: ["performance", "events"],
                descriptionText: "Verzögert Funktionsaufrufe – ideal für Such-Eingaben und Resize-Events."
            ),
            Snippet(
                title: "Guard-let (Swift)",
                code: """
                guard let wert = optionalerWert else {
                    return
                }
                verwende(wert)
                """,
                language: .swift, topic: "Grundlagen",
                difficulty: 1, tags: ["optionals", "guard"],
                descriptionText: "Frühe Rückkehr statt verschachtelter if-let-Pyramiden."
            ),
            Snippet(
                title: "Gruppieren & zählen (SQL)",
                code: """
                SELECT sprache, COUNT(*) AS anzahl
                FROM snippets
                GROUP BY sprache
                ORDER BY anzahl DESC;
                """,
                language: .sql, topic: "Abfragen",
                difficulty: 2, tags: ["aggregation", "group by"],
                output: "python | 42\\nswift  | 30",
                isFavorite: true
            )
        ]
    }
}
