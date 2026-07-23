//
//  NookApp.swift
//  Nook
//

import SwiftUI
import SwiftData

@main
struct NookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var updater = UpdaterController()

    @AppStorage("appSprache") private var appSpracheRaw = AppSprache.system.rawValue

    /// Gewählte Oberflächensprache – überschreibt die Locale aller Szenen live.
    private var oberflaechenLocale: Locale {
        switch appSpracheRaw {
        case AppSprache.deutsch.rawValue:  return Locale(identifier: "de")
        case AppSprache.englisch.rawValue: return Locale(identifier: "en")
        default:                           return .autoupdatingCurrent
        }
    }

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
                .environment(\.locale, oberflaechenLocale)
                .environmentObject(updater)
        }
        .defaultSize(width: 1200, height: 760)
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Auf Updates prüfen …") { updater.nachUpdatesSuchen() }
                    .disabled(!updater.kannPruefen)
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environment(\.locale, oberflaechenLocale)
                .environmentObject(updater)
        } label: {
            Image(systemName: "curlybraces")
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)

        Settings {
            SettingsView()
                .environment(\.locale, oberflaechenLocale)
                .environmentObject(updater)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {

    private var globalShortcutMonitor: Any?
    private var localShortcutMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Beim Start als vollwertige App (.regular): Nook öffnet ohnehin sofort
        // das Hauptfenster, also gehören Dock-Icon UND App-Icon in Fenster-
        // Verwaltung, Stage Manager, Window-Tiling und ⌘-Tab dazu. Startet die
        // App dagegen als .accessory, fehlt das Icon in genau diesen Ansichten
        // (das nachträgliche Umschalten auf .regular kommt für das Tiling-Panel
        // zu spät). Sind später ALLE Fenster geschlossen, schaltet der
        // willClose-Observer unten zurück auf .accessory (reiner Menüleisten-
        // Betrieb).
        NSApp.setActivationPolicy(.regular)

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

        // Beim Start das Hauptfenster nach vorn holen. Ohne das startet Nook
        // als .accessory unsichtbar hinter anderen Fenstern (kein Dock-Icon) und
        // wirkt „tot". Sobald ein Fenster main wird, schaltet der Observer oben
        // auf .regular; schließt der Nutzer es, lebt Nook in der Menüleiste weiter.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.activate(ignoringOtherApps: true)
            let fenster = NSApp.windows.first {
                $0.canBecomeMain && !$0.isKind(of: NSPanel.self)
            }
            fenster?.makeKeyAndOrderFront(nil)
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
