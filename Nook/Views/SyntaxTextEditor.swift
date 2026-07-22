//
//  SyntaxTextEditor.swift
//  Nook
//
//  Nativer Code-Editor auf Basis von NSTextView:
//  - Live Syntax-Highlighting direkt beim Tippen
//  - Keine Autokorrektur, keine Smart-Anführungszeichen, kein Rechtschreibcheck
//  - Monospace-Schrift, horizontales Scrollen (kein Zeilenumbruch)
//  - Tab → 4 Leerzeichen
//  - Reagiert auf Theme- und Schriftgrößenänderungen in Echtzeit
//

import SwiftUI
import AppKit

struct SyntaxTextEditor: NSViewRepresentable {
    @Binding var text: String
    let highlightName: String

    @AppStorage("syntaxTheme")  private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("codeFontSize") private var codeFontSize: Double = 12.5

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView   = NSTextView()

        // Code-Editor: alle Autokorrektur-Features deaktivieren
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled  = false
        textView.isAutomaticDashSubstitutionEnabled   = false
        textView.isAutomaticTextReplacementEnabled    = false
        textView.isAutomaticLinkDetectionEnabled      = false
        textView.isContinuousSpellCheckingEnabled     = false
        textView.isGrammarCheckingEnabled             = false
        textView.smartInsertDeleteEnabled             = false
        textView.allowsUndo                           = true
        textView.isRichText                           = true  // Pflicht für AttributedString
        textView.usesFontPanel                        = false
        textView.importsGraphics                      = false

        // Horizontales Scrollen: kein Zeilenumbruch
        textView.isHorizontallyResizable              = true
        textView.isVerticallyResizable                = true
        textView.autoresizingMask                     = []
        textView.textContainer?.widthTracksTextView   = false
        textView.textContainer?.containerSize         = CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                               height: CGFloat.greatestFiniteMagnitude)
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = CGSize(width: 4, height: 10)

        textView.delegate = context.coordinator

        // ScrollView
        scrollView.hasVerticalScroller   = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers    = true
        scrollView.drawsBackground       = true
        scrollView.documentView          = textView

        // Initiales Highlighting und Theme anwenden
        context.coordinator.refresh(
            textView: textView, scrollView: scrollView,
            code: text, lang: highlightName,
            theme: syntaxTheme, fontSize: codeFontSize
        )
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        guard !context.coordinator.isApplying else { return }

        let coord = context.coordinator
        let stateChanged = coord.lastText      != text
                        || coord.lastLang      != highlightName
                        || coord.lastTheme     != syntaxTheme
                        || coord.lastFontSize  != codeFontSize

        if stateChanged {
            coord.refresh(
                textView: textView, scrollView: scrollView,
                code: text, lang: highlightName,
                theme: syntaxTheme, fontSize: codeFontSize
            )
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxTextEditor
        var isApplying   = false
        var lastText     = ""
        var lastLang     = ""
        var lastTheme: SyntaxTheme  = .catppuccinMocha
        var lastFontSize: Double    = 12.5

        init(_ parent: SyntaxTextEditor) { self.parent = parent }

        /// Wendet Theme-Farben + Syntax-Highlighting an (kombiniert, um doppelten Durchlauf zu vermeiden).
        func refresh(textView: NSTextView, scrollView: NSScrollView,
                     code: String, lang: String,
                     theme: SyntaxTheme, fontSize: Double) {
            isApplying = true
            defer { isApplying = false }

            // Hintergrundfarbe
            let bg = NSColor(theme.hintergrundFarbe)
            textView.backgroundColor     = bg
            textView.insertionPointColor = .white
            scrollView.backgroundColor   = bg

            // Cursor-Position sichern
            let saved   = textView.selectedRange()
            let codeLen = (code as NSString).length

            // Text einsetzen falls nötig (externer Update, z.B. initialCode)
            if textView.string != code {
                textView.string = code
            }

            // Highlighting in-place (nur Attribute, kein String-Ersatz)
            if let storage = textView.textStorage {
                SyntaxHighlighter.applyHighlightingInPlace(
                    storage: storage, code: code,
                    language: lang, theme: theme, fontSize: fontSize
                )
            }

            // Cursor wiederherstellen
            let safeLocation = min(saved.location, codeLen)
            let safeLength   = min(saved.length, max(0, codeLen - safeLocation))
            textView.setSelectedRange(NSRange(location: safeLocation, length: safeLength))

            lastText     = code
            lastLang     = lang
            lastTheme    = theme
            lastFontSize = fontSize
        }

        // MARK: NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard !isApplying else { return }
            guard let textView = notification.object as? NSTextView else { return }

            let code = textView.string
            parent.text = code  // SwiftUI-Binding aktualisieren

            // Highlighting nach jeder Eingabe neu berechnen
            isApplying = true
            defer { isApplying = false }

            if let storage = textView.textStorage {
                SyntaxHighlighter.applyHighlightingInPlace(
                    storage: storage, code: code,
                    language: parent.highlightName,
                    theme: parent.syntaxTheme,
                    fontSize: parent.codeFontSize
                )
            }

            lastText = code
            lastLang = parent.highlightName
            lastTheme = parent.syntaxTheme
            lastFontSize = parent.codeFontSize
        }

        // Tab → 4 Leerzeichen (statt echten Tab-Charakter)
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                textView.insertText("    ", replacementRange: textView.selectedRange())
                return true
            }
            // Shift+Tab: 4 Leerzeichen am Zeilenanfang entfernen
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                let sel    = textView.selectedRange()
                let nsStr  = textView.string as NSString
                let lineRange = nsStr.lineRange(for: NSRange(location: sel.location, length: 0))
                let lineStr   = nsStr.substring(with: lineRange)
                if lineStr.hasPrefix("    ") {
                    if textView.shouldChangeText(in: lineRange, replacementString: String(lineStr.dropFirst(4))) {
                        textView.replaceCharacters(in: lineRange, with: String(lineStr.dropFirst(4)))
                        textView.didChangeText()
                    }
                }
                return true
            }
            return false
        }
    }
}
