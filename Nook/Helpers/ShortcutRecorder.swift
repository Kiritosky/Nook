//
//  ShortcutRecorder.swift
//  Nook
//
//  Tastaturkürzel aufnehmen, speichern und anzeigen.
//

import SwiftUI
import AppKit

// MARK: - StoredShortcut

struct StoredShortcut: RawRepresentable, Equatable {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags

    static let defaultGlobal = StoredShortcut(keyCode: 49, modifiers: [.command, .shift])

    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode   = keyCode
        self.modifiers = modifiers.intersection(.deviceIndependentFlagsMask).subtracting(.capsLock)
    }

    var rawValue: String { "\(keyCode):\(modifiers.rawValue)" }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: ":").map { String($0) }
        guard parts.count == 2,
              let kc    = UInt16(parts[0]),
              let mfRaw = UInt(parts[1]) else { return nil }
        self.keyCode   = kc
        self.modifiers = NSEvent.ModifierFlags(rawValue: mfRaw)
    }

    // Lesbarer Anzeige-String, z.B. "⌘⇧Space"
    var displayString: String {
        var s = ""
        if modifiers.contains(.control) { s += "⌃" }
        if modifiers.contains(.option)  { s += "⌥" }
        if modifiers.contains(.shift)   { s += "⇧" }
        if modifiers.contains(.command) { s += "⌘" }
        s += Self.keyName(for: keyCode)
        return s
    }

    // Tastencodes → lesbarer Name (QWERTY-Belegung)
    static func keyName(for code: UInt16) -> String {
        switch code {
        case 49:  return "Space"
        case 36:  return "↩";   case 53:  return "⎋"
        case 51:  return "⌫";   case 117: return "⌦"
        case 48:  return "⇥"
        case 126: return "↑";   case 125: return "↓"
        case 123: return "←";   case 124: return "→"
        case 116: return "⇞";   case 121: return "⇟"
        case 115: return "↖";   case 119: return "↘"
        case 122: return "F1";  case 120: return "F2";  case 99:  return "F3"
        case 118: return "F4";  case 96:  return "F5";  case 97:  return "F6"
        case 98:  return "F7";  case 100: return "F8";  case 101: return "F9"
        case 109: return "F10"; case 103: return "F11"; case 111: return "F12"
        // Buchstaben
        case 0:  return "A"; case 11: return "B"; case 8:  return "C"
        case 2:  return "D"; case 14: return "E"; case 3:  return "F"
        case 5:  return "G"; case 4:  return "H"; case 34: return "I"
        case 38: return "J"; case 40: return "K"; case 37: return "L"
        case 46: return "M"; case 45: return "N"; case 31: return "O"
        case 35: return "P"; case 12: return "Q"; case 15: return "R"
        case 1:  return "S"; case 17: return "T"; case 32: return "U"
        case 9:  return "V"; case 13: return "W"; case 7:  return "X"
        case 16: return "Y"; case 6:  return "Z"
        // Zahlen
        case 29: return "0"; case 18: return "1"; case 19: return "2"
        case 20: return "3"; case 21: return "4"; case 23: return "5"
        case 22: return "6"; case 26: return "7"; case 28: return "8"; case 25: return "9"
        // Sonderzeichen
        case 27: return "-"; case 24: return "="; case 33: return "["
        case 30: return "]"; case 41: return ";"; case 39: return "'"
        case 43: return ","; case 47: return "."; case 44: return "/"
        case 42: return "\\"; case 50: return "`"
        default: return "?"
        }
    }
}

// MARK: - RecorderNSView

final class RecorderNSView: NSView {
    var shortcut: StoredShortcut?
    var onShortcutChanged: ((StoredShortcut?) -> Void)?
    private(set) var isRecording = false

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 160, height: 26) }

    // MARK: Focus & Maus

    override func mouseDown(with event: NSEvent) {
        if isRecording { stopRecording() }
        else           { window?.makeFirstResponder(self); isRecording = true; needsDisplay = true }
    }

    override func becomeFirstResponder() -> Bool { needsDisplay = true; return super.becomeFirstResponder() }

    override func resignFirstResponder() -> Bool {
        if isRecording { isRecording = false; needsDisplay = true }
        return super.resignFirstResponder()
    }

    private func stopRecording() {
        isRecording = false
        needsDisplay = true
        window?.makeFirstResponder(nil)
    }

    // MARK: Tasten aufnehmen

    // Tasten-Codes, die nur Modifier-Tasten repräsentieren (Cmd, Shift, Opt, Ctrl, Fn)
    private let modifierOnlyKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        // ⎋ → abbrechen (kein Kürzel ändern)
        if event.keyCode == 53 { stopRecording(); return }

        // ⌫ / ⌦ → Kürzel löschen
        if event.keyCode == 51 || event.keyCode == 117 {
            shortcut = nil
            onShortcutChanged?(nil)
            stopRecording()
            return
        }

        // Reine Modifier-Tasten ignorieren
        guard !modifierOnlyKeyCodes.contains(event.keyCode) else { return }

        // Mindestens ein Modifier erforderlich
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting(.capsLock)
        guard !mods.isEmpty else { return }

        let newShortcut = StoredShortcut(keyCode: event.keyCode, modifiers: mods)
        shortcut = newShortcut
        onShortcutChanged?(newShortcut)
        stopRecording()
    }

    // MARK: Zeichnen

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)

        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
            NSColor.controlAccentColor.setStroke()
        } else {
            NSColor.controlBackgroundColor.setFill()
            NSColor.separatorColor.setStroke()
        }
        path.fill()
        path.lineWidth = 1
        path.stroke()

        let label: String
        if isRecording {
            label = "Taste drücken…"
        } else if let sc = shortcut {
            label = sc.displayString
        } else {
            label = "Kein Kürzel"
        }

        let color: NSColor = isRecording ? .controlAccentColor
                           : shortcut == nil ? .tertiaryLabelColor : .labelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: shortcut != nil ? .medium : .regular),
            .foregroundColor: color
        ]
        let ns   = label as NSString
        let size = ns.size(withAttributes: attrs)
        ns.draw(at: CGPoint(x: (bounds.width  - size.width)  / 2,
                            y: (bounds.height - size.height) / 2 + 1),
                withAttributes: attrs)
    }
}

// MARK: - ShortcutRecorder (SwiftUI)

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: StoredShortcut?

    func makeNSView(context: Context) -> RecorderNSView {
        let v = RecorderNSView()
        v.shortcut = shortcut
        v.onShortcutChanged = { context.coordinator.handle($0) }
        return v
    }

    func updateNSView(_ v: RecorderNSView, context: Context) {
        if !v.isRecording { v.shortcut = shortcut }
        v.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        var parent: ShortcutRecorder
        init(_ p: ShortcutRecorder) { parent = p }
        func handle(_ s: StoredShortcut?) {
            DispatchQueue.main.async { self.parent.shortcut = s }
        }
    }
}
