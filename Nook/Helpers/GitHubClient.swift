//
//  GitHubClient.swift
//  Nook
//
//  Phase 2 – Feature 8: „Mit GitHub anmelden" (OAuth Device Flow, ohne Server &
//  ohne Client-Secret) + Gists veröffentlichen/importieren. Das Zugriffstoken
//  liegt im Schlüsselbund; das Passwort sieht die App nie (Login läuft im Browser).
//

import Foundation
import AppKit

// MARK: - Fehler & Datentypen

enum GitHubError: LocalizedError {
    case nichtKonfiguriert
    case nichtAngemeldet
    case autorisierung(String)
    case http(Int)
    case ungueltigeAntwort

    var errorDescription: String? {
        switch self {
        case .nichtKonfiguriert: return "Keine GitHub-Client-ID hinterlegt."
        case .nichtAngemeldet:   return "Nicht bei GitHub angemeldet."
        case .autorisierung(let m): return m
        case .http(let c):       return "GitHub-Fehler (HTTP \(c))."
        case .ungueltigeAntwort: return "Unerwartete Antwort von GitHub."
        }
    }
}

struct GeräteCode: Equatable {
    let deviceCode: String
    let userCode: String
    let verificationURL: String
    let interval: Int
    let expiresIn: Int
}

struct GistDatei {
    let name: String
    let inhalt: String
    let sprache: String?
}

// MARK: - Konto (Anmeldestatus + Aktionen)

@Observable
@MainActor
final class GitHubKonto {
    static let shared = GitHubKonto()

    /// Client-ID der GitHub-OAuth-App (Device Flow aktiviert, Scope „gist").
    /// Öffentlich – kein Secret. HIER die Client-ID der eigenen OAuth-App eintragen.
    static let clientID = "Ov23liiOVVQxm3doQT5G"

    private let scope = "gist"
    private let tokenKey = "github-access-token"

    private(set) var benutzer: String?
    private(set) var laeuftAnmeldung = false
    var geräteCode: GeräteCode?
    var fehler: String?

    var istKonfiguriert: Bool { !Self.clientID.isEmpty }
    var istAngemeldet: Bool { Keychain.laden(tokenKey) != nil }

    private init() {
        if istAngemeldet { Task { await ladeBenutzer() } }
    }

    // MARK: Anmelden (Device Flow)

    func anmelden() async {
        guard istKonfiguriert else { fehler = GitHubError.nichtKonfiguriert.errorDescription; return }
        laeuftAnmeldung = true
        fehler = nil
        defer { laeuftAnmeldung = false }
        do {
            let code = try await geräteCodeAnfordern()
            geräteCode = code
            // Verifizierungsseite im Browser öffnen (dort gibt der Nutzer den Code ein).
            if let url = URL(string: code.verificationURL) { NSWorkspace.shared.open(url) }
            let token = try await aufTokenWarten(code)
            Keychain.speichern(token, key: tokenKey)
            geräteCode = nil
            await ladeBenutzer()
        } catch {
            geräteCode = nil
            fehler = error.localizedDescription
        }
    }

    func abmelden() {
        Keychain.loeschen(tokenKey)
        benutzer = nil
        geräteCode = nil
    }

    private func geräteCodeAnfordern() async throws -> GeräteCode {
        var req = URLRequest(url: URL(string: "https://github.com/login/device/code")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = formularKörper(["client_id": Self.clientID, "scope": scope])
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        try prüfeHTTP(resp)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let device = json["device_code"] as? String,
              let user = json["user_code"] as? String,
              let uri = json["verification_uri"] as? String else {
            throw GitHubError.ungueltigeAntwort
        }
        return GeräteCode(
            deviceCode: device, userCode: user, verificationURL: uri,
            interval: json["interval"] as? Int ?? 5,
            expiresIn: json["expires_in"] as? Int ?? 900
        )
    }

    private func aufTokenWarten(_ code: GeräteCode) async throws -> String {
        var wartezeit = code.interval
        let ende = Date().addingTimeInterval(TimeInterval(code.expiresIn))
        while Date() < ende {
            try await Task.sleep(for: .seconds(wartezeit))
            var req = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = formularKörper([
                "client_id": Self.clientID,
                "device_code": code.deviceCode,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
            ])
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw GitHubError.ungueltigeAntwort
            }
            if let token = json["access_token"] as? String { return token }
            switch json["error"] as? String {
            case "authorization_pending": continue
            case "slow_down":             wartezeit += 5
            case "expired_token":         throw GitHubError.autorisierung("Der Anmelde-Code ist abgelaufen. Bitte erneut versuchen.")
            case "access_denied":         throw GitHubError.autorisierung("Anmeldung abgebrochen.")
            default:                      throw GitHubError.autorisierung("Anmeldung fehlgeschlagen.")
            }
        }
        throw GitHubError.autorisierung("Zeit für die Anmeldung abgelaufen.")
    }

    private func ladeBenutzer() async {
        guard let token = Keychain.laden(tokenKey) else { return }
        var req = URLRequest(url: URL(string: "https://api.github.com/user")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let (data, resp) = try? await URLSession.shared.data(for: req),
           (resp as? HTTPURLResponse)?.statusCode == 200,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let login = json["login"] as? String {
            benutzer = login
        }
    }

    // MARK: Gist veröffentlichen / importieren

    /// Erstellt einen Gist und gibt die öffentliche URL zurück.
    func veröffentliche(name: String, inhalt: String, beschreibung: String, öffentlich: Bool) async throws -> URL {
        guard let token = Keychain.laden(tokenKey) else { throw GitHubError.nichtAngemeldet }
        var req = URLRequest(url: URL(string: "https://api.github.com/gists")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "description": beschreibung,
            "public": öffentlich,
            "files": [name: ["content": inhalt.isEmpty ? " " : inhalt]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try prüfeHTTP(resp)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlStr = json["html_url"] as? String, let url = URL(string: urlStr) else {
            throw GitHubError.ungueltigeAntwort
        }
        return url
    }

    /// Lädt die Dateien eines (öffentlichen) Gists. Funktioniert auch ohne Anmeldung.
    func importiere(gistID: String) async throws -> [GistDatei] {
        var req = URLRequest(url: URL(string: "https://api.github.com/gists/\(gistID)")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let token = Keychain.laden(tokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        try prüfeHTTP(resp)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [String: [String: Any]] else {
            throw GitHubError.ungueltigeAntwort
        }
        return files.compactMap { (_, datei) in
            guard let name = datei["filename"] as? String,
                  let inhalt = datei["content"] as? String else { return nil }
            return GistDatei(name: name, inhalt: inhalt, sprache: datei["language"] as? String)
        }
    }

    /// Extrahiert die Gist-ID aus einer URL oder nimmt die Eingabe direkt als ID.
    static func gistID(aus eingabe: String) -> String? {
        let text = eingabe.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        if let url = URL(string: text), url.host?.contains("gist.github.com") == true {
            return url.pathComponents.last { $0 != "/" && !$0.isEmpty }
        }
        // Reine ID (hex)
        return text.allSatisfy { $0.isHexDigit } ? text : nil
    }

    // MARK: Hilfen

    private func formularKörper(_ paare: [String: String]) -> Data {
        paare.map { key, value in
            let v = value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
            return "\(key)=\(v)"
        }
        .joined(separator: "&")
        .data(using: .utf8) ?? Data()
    }

    private func prüfeHTTP(_ resp: URLResponse) throws {
        guard let http = resp as? HTTPURLResponse else { throw GitHubError.ungueltigeAntwort }
        guard (200...299).contains(http.statusCode) else { throw GitHubError.http(http.statusCode) }
    }
}

// MARK: - Schlüsselbund

enum Keychain {
    private static let service = "com.lassegroene.Nook"

    static func speichern(_ wert: String, key: String) {
        loeschen(key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(wert.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func laden(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func loeschen(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
