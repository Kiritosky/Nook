//
//  UpdaterController.swift
//  Nook
//
//  Kapselt den Sparkle-Auto-Updater als ObservableObject, damit die Oberfläche
//  „Nach Updates suchen" anbieten kann. Updates werden mit einem EdDSA-Schlüssel
//  signiert (kein Apple-Developer-Account nötig); der Feed liegt als appcast.xml
//  im Repo (SUFeedURL in der Info.plist).
//

import SwiftUI
import Combine
import Sparkle

@MainActor
final class UpdaterController: ObservableObject {
    private let controller: SPUStandardUpdaterController

    /// Ob gerade nach Updates gesucht werden kann (steuert das Enabled-State).
    @Published var kannPruefen = false

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$kannPruefen)
    }

    /// Startet eine benutzerinitiierte Update-Prüfung (zeigt Sparkles UI).
    func nachUpdatesSuchen() {
        controller.updater.checkForUpdates()
    }
}
