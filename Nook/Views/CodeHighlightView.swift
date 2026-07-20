//
//  CodeHighlightView.swift
//  Nook
//

import SwiftUI
import WebKit

struct CodeHighlightView: View {
    let code: String
    let language: Language

    @State private var hoehe: CGFloat = 120

    var body: some View {
        CodeWebView(code: code, language: language, hoehe: $hoehe)
            .frame(height: max(hoehe, 60))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CodeWebView: NSViewRepresentable {
    let code: String
    let language: Language
    @Binding var hoehe: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html(), baseURL: nil)
    }

    // Höhe nach dem Laden dynamisch messen
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CodeWebView

        init(_ parent: CodeWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                if let h = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.hoehe = h
                    }
                }
            }
        }
    }

    // HTML mit eingebettetem Catppuccin-Mocha-Theme und Highlight.js via CDN
    private func html() -> String {
        let escaped = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <link rel="stylesheet"
              href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/base16/catppuccin-mocha.min.css">
        <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          html, body { background: #1e1e2e; }
          body { padding: 14px 16px; }
          pre  { background: transparent !important; }
          code { font-family: 'SF Mono', 'Menlo', 'Courier New', monospace;
                 font-size: 12.5px;
                 line-height: 1.55;
                 background: transparent !important; }
          .hljs { background: transparent; color: #cdd6f4; }
        </style>
        </head>
        <body>
        <pre><code class="\(language.highlightName)">\(escaped)</code></pre>
        <script>hljs.highlightAll();</script>
        </body>
        </html>
        """
    }
}
