//
//  Components.swift
//  Nook
//

import SwiftUI

// Wiederverwendbare Tag-Pille
struct TagPill: View {
    let text: String
    let farbe: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(farbe.opacity(0.15))
            .foregroundStyle(farbe)
            .clipShape(Capsule())
    }
}

// Filter-Chip für die Filter-Leiste
struct FilterChip: View {
    let label: String
    let aktiv: Bool
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Text(label)
                .font(.caption)
                .fontWeight(aktiv ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(aktiv ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(aktiv ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
