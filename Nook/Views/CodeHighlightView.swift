//
//  CodeHighlightView.swift
//  Nook
//

import SwiftUI
import WebKit

struct CodeHighlightView: View {
    let code: String
    let highlightName: String

    @AppStorage("syntaxTheme")  private var syntaxTheme: SyntaxTheme = .catppuccinMocha
    @AppStorage("codeFontSize") private var codeFontSize: Double = 12.5
    @State private var hoehe: CGFloat = 120

    var body: some View {
        CodeWebView(code: code,
                    highlightName: highlightName,
                    theme: syntaxTheme,
                    fontSize: codeFontSize,
                    hoehe: $hoehe)
            .frame(height: max(hoehe, 60))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CodeWebView: NSViewRepresentable {
    let code: String
    let highlightName: String
    let theme: SyntaxTheme
    let fontSize: Double
    @Binding var hoehe: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html(), baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CodeWebView
        init(_ parent: CodeWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                if let h = result as? CGFloat {
                    DispatchQueue.main.async { self.parent.hoehe = h }
                }
            }
        }
    }

    private func html() -> String {
        let escaped = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let bg = theme.hintergrundHex

        return """
        <!DOCTYPE html><html>
        <head>
        <meta charset="UTF-8">
        <link rel="stylesheet"
              href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/\(theme.cdnSlug).min.css">
        <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          html,body { background:#\(bg); }
          body { padding:14px 16px; }
          pre  { background:transparent !important; }
          code { font-family:'SF Mono','Menlo','Courier New',monospace;
                 font-size:\(fontSize)px; line-height:1.6;
                 background:transparent !important; }
          .hljs { background:transparent; }
        </style>
        </head>
        <body>
        <pre><code class="\(highlightName)">\(escaped)</code></pre>
        <script>hljs.highlightAll();</script>
        </body></html>
        """
    }
}
