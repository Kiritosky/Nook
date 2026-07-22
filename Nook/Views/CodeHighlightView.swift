//
//  CodeHighlightView.swift
//  Nook
//

import SwiftUI

struct CodeHighlightView: View {
    let code: String
    let highlightName: String

    @AppStorage("syntaxTheme")  private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("codeFontSize") private var codeFontSize: Double = 12.5

    var body: some View {
        let attributed = SyntaxHighlighter.highlight(
            code: code,
            language: highlightName,
            theme: syntaxTheme,
            fontSize: codeFontSize
        )
        ScrollView(.horizontal, showsIndicators: false) {
            Text(attributed)
                .textSelection(.enabled)
                // fixedSize() sorgt dafür dass alle Zeilen angezeigt werden
                // und lange Zeilen nicht umbrechen
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(syntaxTheme.hintergrundFarbe)
    }
}
