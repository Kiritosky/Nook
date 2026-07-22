//
//  SyntaxTextEditor.swift
//  Nook
//
//  Nativer Code-Editor (NSTextView):
//  - Zeilennummern (font-metrisch, ohne layoutManager)
//  - Auto-Einrückung beim Enter (gleiche Tiefe wie vorherige Zeile)
//  - Tab → 4 Leerzeichen, Shift+Tab → dedent (auch Mehrfachauswahl)
//  - Klammer- und Anführungszeichen-Ergänzung
//  - Live Syntax-Highlighting, keine Autokorrektur
//
//  Hinweis: Die Text-View wird über NSTextView.scrollableTextView() erzeugt.
//  Ein selbst zusammengebauter TextKit-Stack ODER jeder layoutManager-Zugriff im
//  Draw-Pfad (z. B. ein klassischer Zeilennummern-Ruler) downgraded die View auf
//  macOS 26 mitten im Rendern von TextKit 2 → 1 – dann verschwinden alle Glyphen
//  und sogar benachbarte SwiftUI-Views. Das Lineal unten berechnet die Zeilen-
//  positionen deshalb rein aus der Font-Zeilenhöhe, ohne den layoutManager.
//

import SwiftUI
import AppKit

// MARK: - SyntaxTextEditor (SwiftUI-Wrapper: Zeilennummern-Gutter + Editor)

/// Öffentliche Schnittstelle. Kombiniert einen SwiftUI-Gutter mit Zeilennummern
/// und den nativen Editor. Der Gutter ist SwiftUI, weil ein AppKit-NSRulerView auf
/// macOS 26 das TextKit-2-Rendering der Text-View zerstört (Glyphen + Nachbar-Views
/// verschwinden). Die Scroll-Position wird vom Editor an den Gutter zurückgemeldet.
struct SyntaxTextEditor: View {
    @Binding var text: String
    let highlightName: String

    @AppStorage("syntaxTheme")  private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("codeFontSize") private var codeFontSize: Double = 12.5

    @State private var scrollY: CGFloat = 0
    @State private var caretLine: Int = 0

    private let topInset: CGFloat = 10
    private var lineHeight: CGFloat {
        let font = NSFont.monospacedSystemFont(ofSize: CGFloat(codeFontSize), weight: .regular)
        return NSLayoutManager().defaultLineHeight(for: font)
    }

    var body: some View {
        HStack(spacing: 0) {
            LineNumberGutter(text: text, scrollY: scrollY, caretLine: caretLine,
                             lineHeight: lineHeight, topInset: topInset, theme: syntaxTheme)
                .frame(width: 40)
            SyntaxEditorRepresentable(text: $text, highlightName: highlightName) { newScrollY, newCaret in
                if scrollY   != newScrollY { scrollY = newScrollY }
                if caretLine != newCaret   { caretLine = newCaret }
            }
        }
    }
}

// MARK: - Zeilennummern-Gutter (SwiftUI)

private struct LineNumberGutter: View {
    let text: String
    let scrollY: CGFloat
    let caretLine: Int
    let lineHeight: CGFloat
    let topInset: CGFloat
    let theme: SyntaxTheme

    private var lineCount: Int {
        if text.isEmpty { return 1 }
        return text.reduce(1) { $0 + ($1 == "\n" ? 1 : 0) }
    }

    var body: some View {
        Canvas { ctx, size in
            for i in 0..<lineCount {
                let y = topInset + CGFloat(i) * lineHeight - scrollY + lineHeight / 2
                guard y >= -lineHeight && y <= size.height + lineHeight else { continue }
                let active = (i == caretLine)
                let color  = active ? theme.tokenColors.plain : theme.tokenColors.comment
                var label  = ctx.resolve(
                    Text("\(i + 1)")
                        .font(.system(size: 10, weight: active ? .medium : .regular, design: .monospaced))
                        .foregroundColor(color)
                )
                label.shading = .color(color)
                ctx.draw(label, at: CGPoint(x: size.width - 7, y: y), anchor: .trailing)
            }
        }
        .background(
            ZStack(alignment: .trailing) {
                Color(theme.hintergrundFarbe)
                Color.black.opacity(theme.isLight ? 0.04 : 0.12)
                Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1)
            }
        )
    }
}

// MARK: - SyntaxEditorRepresentable (nativer NSTextView-Editor)

private struct SyntaxEditorRepresentable: NSViewRepresentable {
    @Binding var text: String
    let highlightName: String
    /// Meldet (scrollOffsetY, caretLineIndex) an den SwiftUI-Gutter zurück.
    let onMetrics: (CGFloat, Int) -> Void

    @AppStorage("syntaxTheme")  private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("codeFontSize") private var codeFontSize: Double = 12.5

    func makeNSView(context: Context) -> NSScrollView {
        // WICHTIG: NSTextView.scrollableTextView() liefert eine korrekt initialisierte
        // Text-View samt funktionierendem Text-System. Ein selbst erzeugter NSTextView
        // (Subklasse, manueller TextKit-Stack oder Null-Frame) rendert auf macOS 26
        // zwar Layout (Zeilennummern), aber KEINE Glyphen → der Code bliebe unsichtbar.
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller   = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers    = true
        scrollView.drawsBackground       = true
        scrollView.borderType            = .noBorder

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Alle Autokorrektur-Features deaktivieren
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled  = false
        textView.isAutomaticDashSubstitutionEnabled   = false
        textView.isAutomaticTextReplacementEnabled    = false
        textView.isAutomaticLinkDetectionEnabled      = false
        textView.isContinuousSpellCheckingEnabled     = false
        textView.isGrammarCheckingEnabled             = false
        textView.smartInsertDeleteEnabled             = false
        textView.allowsUndo                           = true
        textView.isRichText                           = true
        textView.usesFontPanel                        = false
        textView.importsGraphics                      = false

        // No-Wrap / horizontales Scrollen
        textView.isHorizontallyResizable = true
        textView.autoresizingMask        = [.width]
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                                       height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = CGSize(width: 4, height: 10)

        textView.delegate = context.coordinator

        // Scroll-Position an den SwiftUI-Gutter zurückmelden
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollChanged(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView)

        context.coordinator.scrollView = scrollView
        context.coordinator.refresh(
            textView: textView, scrollView: scrollView,
            code: text, lang: highlightName,
            theme: syntaxTheme, fontSize: codeFontSize
        )
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.parent = self   // frische onMetrics-Closure übernehmen
        guard !context.coordinator.isApplying else { return }

        let c = context.coordinator
        let textChanged  = c.lastText     != text
        let langChanged  = c.lastLang     != highlightName
        let themeChanged = c.lastTheme    != syntaxTheme
        let fontChanged  = c.lastFontSize != codeFontSize
        let changed = textChanged || langChanged || themeChanged || fontChanged
        if changed {
            c.refresh(textView: textView, scrollView: scrollView,
                      code: text, lang: highlightName,
                      theme: syntaxTheme, fontSize: codeFontSize)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxEditorRepresentable
        weak var scrollView: NSScrollView?
        var isApplying   = false
        var lastText     = ""
        var lastLang     = ""
        var lastTheme: SyntaxTheme = .catppuccinMocha
        var lastFontSize: Double   = 12.5

        init(_ parent: SyntaxEditorRepresentable) { self.parent = parent }

        deinit { NotificationCenter.default.removeObserver(self) }

        /// Scroll-Offset + aktuelle Cursor-Zeile an den SwiftUI-Gutter melden.
        private func reportMetrics() {
            guard let sv = scrollView,
                  let tv = sv.documentView as? NSTextView else { return }
            let offsetY = sv.contentView.bounds.origin.y
            let caret   = min(tv.selectedRange().location, (tv.string as NSString).length)
            let caretLine = caret == 0 ? 0
                : (tv.string as NSString).substring(to: caret).reduce(0) { $0 + ($1 == "\n" ? 1 : 0) }
            parent.onMetrics(offsetY, caretLine)
        }

        @objc func scrollChanged(_ n: Notification) { reportMetrics() }

        func refresh(textView: NSTextView, scrollView: NSScrollView,
                     code: String, lang: String,
                     theme: SyntaxTheme, fontSize: Double) {
            isApplying = true
            defer { isApplying = false }

            let bg   = NSColor(theme.hintergrundFarbe)
            let tc   = theme.tokenColors
            let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)

            textView.backgroundColor     = bg
            textView.insertionPointColor = theme.isLight ? .black : .white
            scrollView.backgroundColor   = bg

            // Typing-Attributes vorab setzen: bestimmt Farbe/Font für neuen Text.
            // KRITISCH: ohne dies verwendet NSTextView die System-Standardfarbe (schwarz),
            // die auf dunklem Theme-Hintergrund unsichtbar ist.
            textView.typingAttributes = [
                .font:            font,
                .foregroundColor: NSColor(tc.plain)
            ]

            let saved   = textView.selectedRange()
            let codeLen = (code as NSString).length

            if textView.string != code { textView.string = code }

            if let storage = textView.textStorage {
                SyntaxHighlighter.applyHighlightingInPlace(
                    storage: storage, code: code,
                    language: lang, theme: theme, fontSize: fontSize
                )
            }

            // Nach Highlighting erneut setzen (string= und applyHighlighting können es zurücksetzen)
            textView.typingAttributes = [
                .font:            font,
                .foregroundColor: NSColor(tc.plain)
            ]

            let safeLoc = min(saved.location, codeLen)
            let safeLen = min(saved.length, max(0, codeLen - safeLoc))
            textView.setSelectedRange(NSRange(location: safeLoc, length: safeLen))

            lastText = code; lastLang = lang; lastTheme = theme; lastFontSize = fontSize

            // Gutter nach dem Update-Zyklus synchronisieren (nicht während View-Update)
            DispatchQueue.main.async { [weak self] in self?.reportMetrics() }
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplying else { return }
            guard let tv = notification.object as? NSTextView else { return }

            let code = tv.string
            parent.text = code

            isApplying = true
            defer { isApplying = false }

            if let storage = tv.textStorage {
                SyntaxHighlighter.applyHighlightingInPlace(
                    storage: storage, code: code,
                    language: parent.highlightName,
                    theme: parent.syntaxTheme,
                    fontSize: parent.codeFontSize
                )
            }
            // Typing-Attributes nach Highlighting wiederherstellen
            let tc   = parent.syntaxTheme.tokenColors
            let font = NSFont.monospacedSystemFont(ofSize: CGFloat(parent.codeFontSize), weight: .regular)
            tv.typingAttributes = [.font: font, .foregroundColor: NSColor(tc.plain)]

            lastText = code; lastLang = parent.highlightName
            lastTheme = parent.syntaxTheme; lastFontSize = parent.codeFontSize

            reportMetrics()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            tv.setNeedsDisplay(tv.visibleRect)
            reportMetrics()
        }

        // MARK: - Tab / Shift+Tab / Enter

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Tab → 4 Leerzeichen (oder ausgewählte Zeilen einrücken)
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                let sel   = textView.selectedRange()
                let nsStr = textView.string as NSString
                if sel.length > 0 {
                    indentLines(textView, range: sel, nsStr: nsStr, add: true)
                } else {
                    textView.insertText("    ", replacementRange: sel)
                }
                return true
            }
            // Shift+Tab → ausgewählte Zeilen ausrücken
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                let sel   = textView.selectedRange()
                let nsStr = textView.string as NSString
                indentLines(textView, range: sel, nsStr: nsStr, add: false)
                return true
            }
            // Enter → Einrückung der aktuellen Zeile beibehalten
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let sel   = textView.selectedRange()
                let nsStr = textView.string as NSString
                let lineRange = nsStr.lineRange(for: NSRange(location: sel.location, length: 0))
                let lineStr   = nsStr.substring(with: lineRange)
                let indent    = String(lineStr.prefix { $0 == " " || $0 == "\t" })
                textView.insertText("\n" + indent, replacementRange: sel)
                return true
            }
            return false
        }

        private func indentLines(_ tv: NSTextView, range: NSRange, nsStr: NSString, add: Bool) {
            let lineRange = nsStr.lineRange(for: range)
            var lines = nsStr.substring(with: lineRange).components(separatedBy: "\n")
            let trailingNewline = lines.last == ""
            if trailingNewline { lines.removeLast() }
            let modified = lines.map { line -> String in
                if add { return "    " + line }
                if line.hasPrefix("    ") { return String(line.dropFirst(4)) }
                if line.hasPrefix("\t") { return String(line.dropFirst()) }
                return line
            }.joined(separator: "\n")
            let final = trailingNewline ? modified + "\n" : modified
            if tv.shouldChangeText(in: lineRange, replacementString: final) {
                tv.replaceCharacters(in: lineRange, with: final)
                tv.didChangeText()
                tv.setSelectedRange(NSRange(location: lineRange.location, length: (final as NSString).length))
            }
        }

        // MARK: - Klammer- & Anführungszeichen-Ergänzung

        private let bracketPairs: [Character: String] = ["(": ")", "[": "]", "{": "}"]
        private let closers: Set<Character> = [")", "]", "}"]
        private let quotePairs: [Character: String] = ["\"": "\"", "`": "`"]

        func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString: String?) -> Bool {
            // Nur einzelne Zeichen behandeln (str.count > 1 → z.B. Einfügen, Autoclosing-Insert)
            guard let str = replacementString, str.count == 1, let ch = str.first else { return true }

            let nsStr = textView.string as NSString

            // Schließende Klammer überspringen, wenn sie schon da ist
            if closers.contains(ch) && range.length == 0 && range.location < nsStr.length {
                let next = nsStr.substring(with: NSRange(location: range.location, length: 1))
                if next == str {
                    textView.setSelectedRange(NSRange(location: range.location + 1, length: 0))
                    return false
                }
            }

            // Auswahl in Klammern einschließen
            if range.length > 0, let close = bracketPairs[ch] {
                let selected = nsStr.substring(with: range)
                textView.insertText("\(ch)\(selected)\(close)", replacementRange: range)
                textView.setSelectedRange(NSRange(location: range.location + 1, length: range.length))
                return false
            }

            // Öffnende Klammer: schließende asynchron einfügen
            if range.length == 0, let close = bracketPairs[ch] {
                let insertAt = range.location + 1
                DispatchQueue.main.async { [weak textView] in
                    guard let tv = textView else { return }
                    let len = (tv.string as NSString).length
                    guard insertAt <= len else { return }
                    tv.insertText(close, replacementRange: NSRange(location: insertAt, length: 0))
                    tv.setSelectedRange(NSRange(location: insertAt, length: 0))
                }
                return true
            }

            // Anführungszeichen: nur schließen, wenn nächstes Zeichen Whitespace/Satzzeichen ist
            if range.length == 0, let close = quotePairs[ch] {
                let prevSame = range.location > 0 &&
                    Character(UnicodeScalar(nsStr.character(at: range.location - 1))!) == ch
                let nextGood: Bool
                if range.location >= nsStr.length {
                    nextGood = true
                } else {
                    let next = Character(UnicodeScalar(nsStr.character(at: range.location))!)
                    nextGood = next.isWhitespace || ",;)]}\\".contains(next)
                }
                if !prevSame && nextGood {
                    let insertAt = range.location + 1
                    DispatchQueue.main.async { [weak textView] in
                        guard let tv = textView else { return }
                        let len = (tv.string as NSString).length
                        guard insertAt <= len else { return }
                        tv.insertText(close, replacementRange: NSRange(location: insertAt, length: 0))
                        tv.setSelectedRange(NSRange(location: insertAt, length: 0))
                    }
                    return true
                }
            }

            return true
        }
    }
}
