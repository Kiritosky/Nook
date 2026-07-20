//
//  NookApp.swift
//  Nook
//
//  Created by Lasse Gröne on 20.07.26.
//

import SwiftUI
import SwiftData

@main
struct NookApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Snippet.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup(id: "hauptfenster") {
            ContentView()
                .frame(minWidth: 820, minHeight: 520)
        }
        .defaultSize(width: 1100, height: 720)
        .modelContainer(sharedModelContainer)

        MenuBarExtra("Nook", systemImage: "doc.text") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)
    }
}
