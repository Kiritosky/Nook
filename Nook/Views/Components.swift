//
//  Components.swift
//  Nook
//

import SwiftUI

// MARK: - Color Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - FarbIcon

struct FarbIcon: View {
    let symbol: String
    let farbe: Color
    var groesse: CGFloat = 28

    var body: some View {
        RoundedRectangle(cornerRadius: groesse * 0.26)
            .fill(farbe.gradient)
            .frame(width: groesse, height: groesse)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: groesse * 0.44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            // Spekulares Highlight (Glasoptik)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: groesse * 0.26)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: groesse, height: groesse * 0.52)
                    .clipShape(
                        .rect(
                            topLeadingRadius: groesse * 0.26,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: groesse * 0.26
                        )
                    )
            }
            .shadow(color: farbe.opacity(0.45), radius: groesse * 0.18, x: 0, y: groesse * 0.1)
    }
}

// MARK: - TagPill

struct TagPill: View {
    let text: String
    let farbe: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(farbe.opacity(0.12))
            .foregroundStyle(farbe)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(farbe.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let label: String
    var symbol: String? = nil
    let aktiv: Bool
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 4) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 9, weight: .semibold))
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(aktiv ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(aktiv ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundStyle(aktiv ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(aktiv ? Color.clear : Color.secondary.opacity(0.15), lineWidth: 0.5)
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: aktiv)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let titel: String

    var body: some View {
        HStack(spacing: 7) {
            Capsule()
                .fill(Color.accentColor.opacity(0.5))
                .frame(width: 3, height: 11)
            Text(titel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }
}

// MARK: - SchwierigkeitSterne

struct SchwierigkeitSterne: View {
    let stufe: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: i <= stufe ? "circle.fill" : "circle")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(i <= stufe ? stufenFarbe : Color.secondary.opacity(0.22))
            }
        }
    }

    var stufenFarbe: Color {
        switch stufe {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .secondary
        }
    }
}

// MARK: - SidebarZeile

struct SidebarZeile: View {
    let symbol: String
    let farbe: Color
    let titel: String
    let anzahl: Int

    var body: some View {
        HStack(spacing: 10) {
            FarbIcon(symbol: symbol, farbe: farbe, groesse: 26)

            Text(titel)
                .font(.system(.body, weight: .medium))
                .lineLimit(1)

            Spacer()

            if anzahl > 0 {
                Text("\(anzahl)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 1)
        .contentShape(Rectangle())
    }
}
