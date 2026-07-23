//
//  BackupManager.swift
//  Nook
//
//  Automatische, in sich geschlossene Sicherung der gesamten Sammlung.
//
//  Backups liegen im App-Container (Application Support/Nook/Backups) und
//  brauchen daher weder eine Sandbox-Berechtigung noch eine Nutzer-Auswahl.
//  Ein Backup ist ein vollständiger Schnappschuss (inkl. Papierkorb) im selben
//  JSON-Format wie der manuelle Export und lässt sich jederzeit importieren.
//

import Foundation
import SwiftData

@MainActor
enum BackupManager {

    // MARK: Einstellungs-Schlüssel (spiegeln @AppStorage in den Einstellungen)

    static let enabledKey  = "autoBackupAktiv"
    static let intervalKey = "autoBackupIntervallTage"   // 0 = bei jedem Start
    static let keepKey     = "autoBackupAnzahl"
    static let lastRunKey  = "autoBackupLetzterLauf"

    static let standardIntervallTage = 1
    static let standardAnzahl = 10

    // MARK: Speicherort

    /// Verzeichnis der Sicherungen im App-Container. Wird bei Bedarf erstellt.
    static func backupOrdner() throws -> URL {
        let fm = FileManager.default
        let support = try fm.url(for: .applicationSupportDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true)
        let ordner = support.appendingPathComponent("Nook/Backups", isDirectory: true)
        try fm.createDirectory(at: ordner, withIntermediateDirectories: true)
        return ordner
    }

    // MARK: Auflisten

    struct BackupDatei: Identifiable {
        let id: URL
        let erstellt: Date
        let groesse: Int
        var url: URL { id }
        var name: String { id.lastPathComponent }
    }

    /// Alle vorhandenen Sicherungen, neueste zuerst.
    static func vorhandene() -> [BackupDatei] {
        guard let ordner = try? backupOrdner() else { return [] }
        return vorhandene(in: ordner)
    }

    /// Wie `vorhandene()`, aber für ein beliebiges Verzeichnis (testbar).
    static func vorhandene(in ordner: URL) -> [BackupDatei] {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(
            at: ordner,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles])) ?? []
        return urls
            .filter { $0.pathExtension.lowercased() == "json" }
            .map { url -> BackupDatei in
                let werte = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                return BackupDatei(id: url,
                                   erstellt: werte?.creationDate ?? .distantPast,
                                   groesse: werte?.fileSize ?? 0)
            }
            .sorted { $0.erstellt > $1.erstellt }
    }

    // MARK: Sichern

    /// Schreibt sofort ein vollständiges Backup und rotiert alte Sicherungen weg.
    /// - Returns: URL der geschriebenen Datei.
    @discardableResult
    static func sichern(context: ModelContext) throws -> URL {
        let snippets = try context.fetch(FetchDescriptor<Snippet>())
        let ordner = try backupOrdner()
        let data = try SnippetImportExport.exportieren(snippets)
        let url = ordner.appendingPathComponent("Nook-\(zeitstempel()).json")
        try data.write(to: url, options: .atomic)
        UserDefaults.standard.set(Date(), forKey: lastRunKey)
        rotieren()
        return url
    }

    /// Sichert nur, wenn aktiviert und das Intervall abgelaufen ist. Fehler
    /// werden bewusst verschluckt – eine fehlgeschlagene Auto-Sicherung darf den
    /// App-Start nie stören.
    static func sichereFalligFalls(context: ModelContext) {
        let defaults = UserDefaults.standard
        let aktiviert = defaults.object(forKey: enabledKey) as? Bool ?? true
        guard aktiviert else { return }

        // Nichts zu sichern? Dann auch keinen leeren Schnappschuss anlegen.
        let anzahl = (try? context.fetchCount(FetchDescriptor<Snippet>())) ?? 0
        guard anzahl > 0 else { return }

        let tage = defaults.object(forKey: intervalKey) as? Int ?? standardIntervallTage
        if tage > 0, let letzter = defaults.object(forKey: lastRunKey) as? Date {
            let faellig = letzter.addingTimeInterval(Double(tage) * 86_400)
            if Date() < faellig { return }
        }
        try? sichern(context: context)
    }

    // MARK: Wiederherstellen

    /// Importiert ein Backup in den Kontext (Duplikate werden übersprungen).
    @discardableResult
    static func wiederherstellen(aus url: URL, context: ModelContext) throws -> (neu: Int, uebersprungen: Int) {
        let data = try Data(contentsOf: url)
        let vorhandene = try context.fetch(FetchDescriptor<Snippet>())
        return try SnippetImportExport.importieren(data, context: context, vorhandene: vorhandene)
    }

    // MARK: Rotation

    /// Behält nur die neuesten N Sicherungen (N aus den Einstellungen).
    static func rotieren() {
        guard let ordner = try? backupOrdner() else { return }
        let anzahl = UserDefaults.standard.object(forKey: keepKey) as? Int ?? standardAnzahl
        rotieren(in: ordner, behalte: anzahl)
    }

    /// Wie `rotieren()`, aber für ein beliebiges Verzeichnis + Anzahl (testbar).
    static func rotieren(in ordner: URL, behalte anzahl: Int) {
        guard anzahl > 0 else { return }
        let alle = vorhandene(in: ordner)
        guard alle.count > anzahl else { return }
        for datei in alle.dropFirst(anzahl) {
            try? FileManager.default.removeItem(at: datei.url)
        }
    }

    // MARK: Intern

    private static func zeitstempel() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f.string(from: Date())
    }
}
