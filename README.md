# Nook

**Dein ruhiges, privates Code-Archiv für macOS.**

Nook ist ein persönlicher Wissensspeicher für Code-Snippets — kein Lern-Tool,
sondern ein Notizbuch für Entwickler. Snippets werden nach Sprache, Thema,
Projekt, Tags und Schwierigkeit organisiert und blitzschnell wiedergefunden.
Native SwiftUI-App, lokal, ohne Cloud-Zwang.

---

## Funktionen

- **Snippet-Verwaltung** – Titel, Code, Beschreibung, Beispiel-Output, Tags,
  Favoriten, Anheften.
- **Syntax-Highlighting** – über 20 Sprachen, mehrere Themes, Auto-Theme
  (folgt dem macOS Hell/Dunkel-Modus), eigene Sprachen definierbar.
- **Schnellzugriff** – Menüleisten-App mit Suche + global konfigurierbarem
  Kürzel, Spotlight-Integration, Drag-&-Drop von Code-Dateien.
- **Organisieren** – schlanke Seitenleiste mit Drill-in-Browser, Tag-zentrierte
  Suche (`#tag` mit Autovervollständigung).
- **Datensicherheit** – Papierkorb mit Rückgängig, JSON-Export/-Import und
  **automatische, rotierende Sicherungen** im App-Ordner.
- **Zweisprachig** – Oberfläche Deutsch/Englisch, live umschaltbar.

---

## Technik

| Bereich        | Technologie                     |
|----------------|---------------------------------|
| UI             | SwiftUI (macOS 26+)             |
| Persistenz     | SwiftData (lokal)               |
| Highlighting   | Highlight.js via WKWebView      |
| Menüleiste     | MenuBarExtra                    |
| Sprache        | Swift 6                         |

Keine Third-Party-Pakete außer Highlight.js.

## Build

```bash
git clone https://github.com/Kiritosky/Nook.git
cd Nook
open Nook.xcodeproj   # in Xcode: Scheme „Nook" → Run (⌘R)
```

Benötigt Xcode mit macOS-26-SDK.

---

## Lizenz

Nook ist **quelloffen einsehbar, aber nicht Open Source im OSI-Sinn.** Es gilt
die [PolyForm Noncommercial License 1.0.0](LICENSE.md).

**Im Klartext:**

- ✅ Du darfst den Code **ansehen, daraus lernen, privat nutzen und für dich
  selbst verändern/forken** — für jeden **nicht-kommerziellen** Zweck.
- ✅ Nutzung durch Bildungseinrichtungen, gemeinnützige Organisationen und
  Behörden ist erlaubt.
- ❌ Du darfst Nook (oder abgeleitete Werke) **nicht kommerziell verwenden** —
  also nicht verkaufen, nicht als bezahlten Dienst anbieten und nicht damit
  Geld verdienen.

Alle kommerziellen Rechte liegen beim Autor. Für eine kommerzielle Lizenz bitte
Kontakt aufnehmen.

Copyright © 2026 Lasse Gröne
