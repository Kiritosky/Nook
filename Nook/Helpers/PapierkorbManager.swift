//
//  PapierkorbManager.swift
//  Nook
//
//  Verwaltet Soft-Delete (Papierkorb) und die "Rückgängig"-Leiste.
//  Löschen setzt nur `deletedAt` – nichts geht sofort verloren.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class PapierkorbManager {
    /// Zuletzt in den Papierkorb verschobenes Snippet – treibt die Undo-Leiste.
    var zuletztGeloescht: Snippet?

    private var ausblendTask: Task<Void, Never>?

    /// Verschiebt ein Snippet in den Papierkorb (reversibel).
    func loeschen(_ snippet: Snippet) {
        snippet.deletedAt = Date()
        SpotlightManager.remove(snippet)
        zuletztGeloescht = snippet
        planeAusblenden()
    }

    /// Macht die letzte Papierkorb-Verschiebung rückgängig.
    func rueckgaengig() {
        ausblendTask?.cancel()
        guard let snippet = zuletztGeloescht else { return }
        snippet.deletedAt = nil
        SpotlightManager.index(snippet)
        zuletztGeloescht = nil
    }

    /// Holt ein einzelnes Snippet aus dem Papierkorb zurück.
    func wiederherstellen(_ snippet: Snippet) {
        snippet.deletedAt = nil
        SpotlightManager.index(snippet)
        if zuletztGeloescht == snippet { zuletztGeloescht = nil }
    }

    /// Entfernt ein Snippet endgültig aus der Datenbank.
    func endgueltigLoeschen(_ snippet: Snippet, context: ModelContext) {
        if zuletztGeloescht == snippet { zuletztGeloescht = nil }
        SpotlightManager.remove(snippet)
        context.delete(snippet)
    }

    /// Leert den Papierkorb komplett.
    func papierkorbLeeren(_ snippets: [Snippet], context: ModelContext) {
        zuletztGeloescht = nil
        for snippet in snippets {
            SpotlightManager.remove(snippet)
            context.delete(snippet)
        }
    }

    private func planeAusblenden() {
        ausblendTask?.cancel()
        ausblendTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            self?.zuletztGeloescht = nil
        }
    }
}
