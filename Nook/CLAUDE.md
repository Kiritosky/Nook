# Nook – Kontext für Claude Code

Dieses Dokument gibt Claude Code den vollständigen Projektkontext für die Nook macOS App.

---

## Was ist Nook?

Nook ist ein persönlicher Code-Wissensspeicher als native macOS App. Kein Lern-Tool, sondern ein ruhiges, privates Archiv – wie ein Notizbuch für Entwickler. Snippets werden nach Sprache, Thema, Projekt und Schwierigkeit organisiert und blitzschnell per Suche wiedergefunden.

---

## Tech-Stack

| Bereich | Technologie |
|---|---|
| UI | SwiftUI (macOS 26+) |
| Datenbank | SwiftData (lokal, kein CloudKit vorerst) |
| Syntax Highlighting | Highlight.js via WKWebView |
| Menubar | MenuBarExtra (SwiftUI) |
| Vertrieb (v3) | Homebrew Cask |

---

## Datenmodell

```swift
enum Language: String, CaseIterable, Codable {
    case python     = "Python"
    case javascript = "JavaScript"
    case swift      = "Swift"
    case sql        = "SQL"
    case html       = "HTML"
    case css        = "CSS"
    case bash       = "Bash"
    case other      = "Sonstiges"
}

@Model
class Snippet {
    var title: String
    var code: String
    var language: Language
    var topic: String
    var project: String?
    var difficulty: Int          // 1 = Anfänger, 2 = Mittel, 3 = Fortgeschritten
    var tags: [String]
    var descriptionText: String?
    var output: String?
    var createdAt: Date
    var isFavorite: Bool
}
```

---

## App-Architektur

```
NookApp
├── MenuBarExtra (Popover)
│   ├── Suchfeld
│   └── Letzte Snippets (Liste)
│
└── Hauptfenster (NavigationSplitView – 3 Spalten)
    ├── Sidebar
    │   ├── Alle Snippets
    │   ├── Favoriten
    │   ├── Nach Sprache
    │   └── Nach Projekt
    ├── Snippet-Liste
    │   ├── Suchfeld
    │   ├── Filter-Leiste
    │   └── Snippet-Karten
    └── Detail-Panel
        ├── Titel & Metadaten
        ├── Code-Block (Syntax Highlighting)
        ├── Beschreibung
        ├── Beispiel-Output
        └── Links
```

---

## Design-System

### Prinzip
Liquid Glass (macOS 26) – durchscheinende Oberflächen, weiche Unschärfe.
In SwiftUI: `.glassBackgroundEffect()`

### Farbpalette
| Name | Hex | Verwendung |
|---|---|---|
| Crust | `#1e1e2e` | Hintergrund (Dark) |
| Surface | `#313244` | Karten, Sidebar |
| Accent | `#89b4fa` | Links, aktive Elemente |
| Success | `#a6e3a1` | Python-Tag, Bestätigungen |
| Keyword | `#cba6f7` | Syntax Highlighting |
| Glass | `rgba(255,255,255,0.08)` | Liquid Glass Flächen |

### Typografie
| Rolle | Größe | Font |
|---|---|---|
| Title | 22px / 500 | SF Pro |
| Headline | 15px / 500 | SF Pro |
| Body | 13px / 400 | SF Pro |
| Caption | 11px / 400 | SF Pro |
| Code | 12px / 400 | SF Mono / Menlo |

**Regel:** UI immer SF Pro, Code immer SF Mono / Menlo.

---

## Konventionen

- Sprache: Swift (kein Objective-C)
- SwiftUI Views immer in eigene Dateien auslagern (eine View pro Datei)
- SwiftData `@Model` Klassen in `/Models/`
- Views in `/Views/`
- Hilfsfunktionen in `/Helpers/`
- Keine Third-Party-Packages außer Highlight.js (via WKWebView, kein SPM)
- Kommentare auf Deutsch

---

## Aktueller Stand

### Abgeschlossen
- Projektplanung & Design System definiert
- Xcode-Projekt angelegt (SwiftUI + SwiftData, Local)

### Phase 1 – in Arbeit
- [x] Xcode-Projekt angelegt
- [ ] `Snippet.swift` Modell anlegen
- [ ] `NookApp.swift` mit `.modelContainer` konfigurieren
- [ ] Einfaches Formular: Snippet erstellen + anzeigen

### Nächste Phasen
- Phase 2: NavigationSplitView Hauptfenster
- Phase 3: MenuBarExtra Integration
- Phase 4: Suche & Syntax Highlighting
- Phase 5: Homebrew Vertrieb

---

## Wichtige Hinweise für Claude Code

- Wir bauen für **macOS 26+** – neue SwiftUI APIs sind verfügbar
- **Kein CloudKit** vorerst – nur lokale SwiftData Persistenz
- Design folgt **Liquid Glass** – `.glassBackgroundEffect()` wo passend
- Beim Erstellen neuer Views immer das **Design-System** oben beachten
- Phase 1 ist noch nicht fertig – fokussiere dich darauf bevor du weiterbaust
