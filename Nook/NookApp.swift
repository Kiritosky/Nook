//
//  NookApp.swift
//  Nook
//

import SwiftUI
import SwiftData

@main
struct NookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Snippet.self, CustomLanguage.self, Projekt.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Persistenter Speicher konnte nicht geöffnet werden (z. B. beschädigt
            // oder fehlgeschlagene Migration). Statt hart abzustürzen fällt die App
            // auf einen flüchtigen Speicher zurück – so bleibt sie bedienbar und die
            // Sammlung auf der Platte wird NICHT überschrieben.
            NSLog("[Nook] Persistenter Speicher fehlgeschlagen: \(error). Fallback: In-Memory.")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let container = try? ModelContainer(for: schema, configurations: [fallback]) {
                return container
            }
            fatalError("ModelContainer konnte weder persistent noch flüchtig erstellt werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup(id: "hauptfenster") {
            ContentView()
                .frame(minWidth: 860, minHeight: 540)
        }
        .defaultSize(width: 1200, height: 760)
        .modelContainer(sharedModelContainer)

        MenuBarExtra {
            MenuBarView()
        } label: {
            Image(systemName: "curlybraces")
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)

        Settings {
            SettingsView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {

    private var globalShortcutMonitor: Any?
    private var localShortcutMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let center = NotificationCenter.default

        center.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { _ in
            NSApp.setActivationPolicy(.regular)
        }

        center.addObserver(
            forName: NSWindow.willEnterFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            NSApp.setActivationPolicy(.regular)
        }

        center.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let hatHauptfenster = NSApp.windows.contains {
                    $0.isVisible && $0.canBecomeMain
                }
                if !hatHauptfenster {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }

        // Globalen Shortcut registrieren (liest aus UserDefaults)
        registriereGlobalenShortcut()

        // Bei Einstellungsänderung neu registrieren
        center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.registriereGlobalenShortcut()
        }
    }

    private func registriereGlobalenShortcut() {
        // Alte Monitore entfernen
        if let m = globalShortcutMonitor { NSEvent.removeMonitor(m); globalShortcutMonitor = nil }
        if let m = localShortcutMonitor  { NSEvent.removeMonitor(m); localShortcutMonitor  = nil }

        // Shortcut aus UserDefaults — Fallback auf Standard (⌘⇧Space)
        let raw = UserDefaults.standard.string(forKey: "globalShortcut")
            ?? StoredShortcut.defaultGlobal.rawValue
        guard let shortcut = StoredShortcut(rawValue: raw) else { return }

        let passt: (NSEvent) -> Bool = { event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting(.capsLock)
            return mods == shortcut.modifiers && event.keyCode == shortcut.keyCode
        }

        globalShortcutMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard passt(event) else { return }
            self?.nookFensterTogglen()
        }
        localShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard passt(event) else { return event }
            self?.nookFensterTogglen()
            return nil
        }
    }

    private func nookFensterTogglen() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            let hauptfenster = NSApp.windows.first { !$0.isKind(of: NSPanel.self) && $0.canBecomeMain }
            if let w = hauptfenster {
                w.makeKeyAndOrderFront(nil)
            } else {
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
