//
//  Design.swift
//  Nook
//
//  Phase 3 – Feste Maßsystem-Tokens für „ruhig & edel": ein einheitliches
//  Raster für Abstände, Radien und Typografie plus ein Glass-Material-Helfer.
//  Neue/überarbeitete Views nutzen diese Tokens statt Streu-Literale.
//

import SwiftUI

// MARK: - Abstände (4-pt-Raster)

enum Abstand {
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let s:   CGFloat = 8
    static let m:   CGFloat = 12
    static let l:   CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 28
}

// MARK: - Eck-Radien

enum Radius {
    static let s:  CGFloat = 6
    static let m:  CGFloat = 8
    static let l:  CGFloat = 10
    static let xl: CGFloat = 12
    static let xxl: CGFloat = 16
}

// MARK: - Typografie (nach Design-System: SF Pro UI, SF Mono Code)

extension Font {
    /// 22 / semibold – Seiten-/Snippet-Titel
    static let nookTitel   = Font.system(size: 22, weight: .semibold)
    /// 15 / medium – Abschnittsüberschrift
    static let nookHeadline = Font.system(size: 15, weight: .medium)
    /// 13 / regular – Fließtext
    static let nookBody    = Font.system(size: 13)
    /// 11 / regular – Beschriftung
    static let nookCaption = Font.system(size: 11)
    /// 12 / monospaced – Code
    static let nookCode    = Font.system(size: 12, design: .monospaced)
}

// MARK: - Glass / Material-Flächen

extension View {
    /// Einheitliche „Liquid-Glass"-Chrome-Fläche (Toolbars, Popover-Kopf/-Fuß,
    /// schwebende Leisten). Zentral, damit Material + Radius überall gleich sind.
    func nookGlass(radius: CGFloat = Radius.xl) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}
