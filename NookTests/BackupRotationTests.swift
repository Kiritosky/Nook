//
//  BackupRotationTests.swift
//  NookTests
//
//  Sichert die Rotation der automatischen Sicherungen ab: nur die neuesten N
//  bleiben erhalten, und "behalte 0" löscht nichts. Läuft in einem temporären
//  Verzeichnis, rührt echte Backups nicht an.
//

import Testing
import Foundation
@testable import Nook

@MainActor
struct BackupRotationTests {

    /// Temporäres Verzeichnis mit `anzahl` Dummy-Sicherungen, aufsteigend datiert
    /// (Datei i ist neuer als i-1). Gibt Verzeichnis + Aufräum-Closure zurück.
    private func macheOrdner(anzahl: Int) throws -> (URL, () -> Void) {
        let fm = FileManager.default
        let ordner = fm.temporaryDirectory.appendingPathComponent("nook-test-\(UUID().uuidString)")
        try fm.createDirectory(at: ordner, withIntermediateDirectories: true)
        for i in 0..<anzahl {
            let url = ordner.appendingPathComponent("Nook-\(i).json")
            try Data("{}".utf8).write(to: url)
            let datum = Date(timeIntervalSince1970: 1_000_000 + Double(i) * 60)
            try fm.setAttributes([.creationDate: datum], ofItemAtPath: url.path)
        }
        return (ordner, { try? fm.removeItem(at: ordner) })
    }

    @Test("Rotation behält nur die neuesten N Sicherungen")
    func rotationBehaeltNeueste() throws {
        let (ordner, aufraeumen) = try macheOrdner(anzahl: 5)
        defer { aufraeumen() }

        BackupManager.rotieren(in: ordner, behalte: 2)

        let uebrig = BackupManager.vorhandene(in: ordner)
        #expect(uebrig.count == 2)
        let namen = Set(uebrig.map(\.name))
        #expect(namen.contains("Nook-4.json"))   // neueste
        #expect(namen.contains("Nook-3.json"))
        #expect(!namen.contains("Nook-0.json"))  // älteste weg
    }

    @Test("Weniger Sicherungen als Limit: nichts wird gelöscht")
    func unterLimitLoeschtNichts() throws {
        let (ordner, aufraeumen) = try macheOrdner(anzahl: 3)
        defer { aufraeumen() }

        BackupManager.rotieren(in: ordner, behalte: 10)
        #expect(BackupManager.vorhandene(in: ordner).count == 3)
    }

    @Test("behalte 0 löscht nichts (Schutz vor Totalverlust)")
    func behalteNullLoeschtNichts() throws {
        let (ordner, aufraeumen) = try macheOrdner(anzahl: 3)
        defer { aufraeumen() }

        BackupManager.rotieren(in: ordner, behalte: 0)
        #expect(BackupManager.vorhandene(in: ordner).count == 3)
    }
}
