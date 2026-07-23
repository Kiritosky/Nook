//
//  Toast.swift
//  Nook
//
//  Phase 3 – Feature 2: dezentes, kurzlebiges Erfolgs-Feedback („Kopiert" …).
//  Zentrale Stelle, damit Kopier-Aktionen überall dasselbe ruhige Signal geben.
//

import SwiftUI

@MainActor
@Observable
final class ToastZentrale {
    static let shared = ToastZentrale()

    private(set) var text: String?
    private(set) var symbol: String = "checkmark.circle.fill"
    private var aufgabe: Task<Void, Never>?

    private init() {}

    func zeige(_ text: String, symbol: String = "checkmark.circle.fill") {
        self.text = text
        self.symbol = symbol
        aufgabe?.cancel()
        aufgabe = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            if !Task.isCancelled { self?.text = nil }
        }
    }
}

private struct NookToast: ViewModifier {
    @State private var zentrale = ToastZentrale.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let text = zentrale.text {
                    HStack(spacing: Abstand.s) {
                        Image(systemName: zentrale.symbol)
                            .foregroundStyle(.green)
                        Text(text)
                            .font(.callout).fontWeight(.medium)
                    }
                    .padding(.horizontal, Abstand.l)
                    .padding(.vertical, Abstand.s + 1)
                    .nookGlass(radius: 20)
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
                    .padding(.bottom, Abstand.xxl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: zentrale.text)
    }
}

extension View {
    /// Blendet zentrale Erfolgs-Toasts (unten, schwebend) über dieser View ein.
    func nookToast() -> some View { modifier(NookToast()) }
}
