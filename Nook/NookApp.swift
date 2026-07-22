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
        let schema = Schema([Snippet.self, CustomLanguage.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let center = NotificationCenter.default

        // Wenn ein normales Fenster aktiv wird → regular (nötig für Fullscreen-Exit)
        center.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { _ in
            NSApp.setActivationPolicy(.regular)
        }

        // Wenn Vollbild betreten wird → sicherstellen dass .regular aktiv ist
        center.addObserver(
            forName: NSWindow.willEnterFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            NSApp.setActivationPolicy(.regular)
        }

        // Wenn Fenster geschlossen: prüfen ob noch ein Hauptfenster offen ist
        center.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Kurz warten damit das Fenster aus NSApp.windows entfernt wird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let hatHauptfenster = NSApp.windows.contains {
                    $0.isVisible && $0.canBecomeMain
                }
                if !hatHauptfenster {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
