//
//  SyntaxHighlighter.swift
//  Nook
//

import SwiftUI

// MARK: - Theme Token Colors

extension SyntaxTheme {
    struct TokenColors {
        let plain: Color
        let keyword: Color
        let string: Color
        let comment: Color
        let number: Color
        let function_: Color
        let type_: Color
    }

    var tokenColors: TokenColors {
        switch self {
        case .catppuccinMocha:
            return .init(plain: Color(hex: "cdd6f4"), keyword: Color(hex: "cba6f7"),
                         string: Color(hex: "a6e3a1"), comment: Color(hex: "6c7086"),
                         number: Color(hex: "fab387"), function_: Color(hex: "89b4fa"),
                         type_: Color(hex: "f9e2af"))
        case .nord:
            return .init(plain: Color(hex: "eceff4"), keyword: Color(hex: "81a1c1"),
                         string: Color(hex: "a3be8c"), comment: Color(hex: "616e88"),
                         number: Color(hex: "b48ead"), function_: Color(hex: "88c0d0"),
                         type_: Color(hex: "ebcb8b"))
        case .githubDark:
            return .init(plain: Color(hex: "e6edf3"), keyword: Color(hex: "ff7b72"),
                         string: Color(hex: "a5d6ff"), comment: Color(hex: "8b949e"),
                         number: Color(hex: "79c0ff"), function_: Color(hex: "d2a8ff"),
                         type_: Color(hex: "ffa657"))
        case .oneDark:
            return .init(plain: Color(hex: "abb2bf"), keyword: Color(hex: "c678dd"),
                         string: Color(hex: "98c379"), comment: Color(hex: "5c6370"),
                         number: Color(hex: "d19a66"), function_: Color(hex: "61afef"),
                         type_: Color(hex: "e5c07b"))
        case .monokai:
            return .init(plain: Color(hex: "f8f8f2"), keyword: Color(hex: "f92672"),
                         string: Color(hex: "e6db74"), comment: Color(hex: "75715e"),
                         number: Color(hex: "ae81ff"), function_: Color(hex: "a6e22e"),
                         type_: Color(hex: "66d9e8"))
        case .tokyoNight:
            return .init(plain: Color(hex: "c0caf5"), keyword: Color(hex: "bb9af7"),
                         string: Color(hex: "9ece6a"), comment: Color(hex: "565f89"),
                         number: Color(hex: "ff9e64"), function_: Color(hex: "7aa2f7"),
                         type_: Color(hex: "2ac3de"))
        }
    }
}

// MARK: - Highlighter

enum SyntaxHighlighter {

    private struct Rule {
        let pattern: String
        let options: NSRegularExpression.Options
        let color: Color

        init(_ pattern: String, _ color: Color, options: NSRegularExpression.Options = .dotMatchesLineSeparators) {
            self.pattern = pattern; self.options = options; self.color = color
        }
    }

    static func highlight(code: String, language: String, theme: SyntaxTheme, fontSize: Double) -> AttributedString {
        let tc = theme.tokenColors
        var result = AttributedString(code)
        result.font = .system(size: CGFloat(fontSize), design: .monospaced)
        result.foregroundColor = tc.plain

        for rule in rules(for: language.lowercased(), tc: tc) {
            applyRule(rule, to: &result, in: code)
        }
        return result
    }

    private static func applyRule(_ rule: Rule, to result: inout AttributedString, in code: String) {
        guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: rule.options) else { return }
        let nsRange = NSRange(code.startIndex..., in: code)
        for match in regex.matches(in: code, range: nsRange) {
            guard let range = Range(match.range, in: code) else { continue }
            let offset = code.distance(from: code.startIndex, to: range.lowerBound)
            let length = code.distance(from: range.lowerBound, to: range.upperBound)
            guard offset >= 0, length > 0 else { continue }
            let s = result.index(result.startIndex, offsetByCharacters: offset)
            let e = result.index(s, offsetByCharacters: length)
            result[s..<e].foregroundColor = rule.color
        }
    }

    // MARK: - Language rules (lowest priority first — later rules overwrite)

    private static func rules(for lang: String, tc: SyntaxTheme.TokenColors) -> [Rule] {
        let numbers      = Rule(#"\b0x[0-9a-fA-F]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#, tc.number)
        let pascal       = Rule(#"\b[A-Z][A-Za-z0-9_]*\b"#, tc.type_)
        let slashLine    = Rule(#"//[^\n]*"#,       tc.comment)
        let blockComment = Rule(#"/\*[\s\S]*?\*/"#, tc.comment)
        let hashComment  = Rule(#"#[^\n]*"#,        tc.comment)
        let dqString     = Rule(#""(?:[^"\\]|\\.)*""#, tc.string)
        let sqString     = Rule(#"'(?:[^'\\]|\\.)*'"#, tc.string)

        switch lang {
        case "python":
            let kw = Rule(#"\b(?:False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield|print|len|range|self|super)\b"#, tc.keyword)
            let doc = Rule(#""""[\s\S]*?"""|'''[\s\S]*?'''"#, tc.string)
            return [numbers, kw, pascal, doc, dqString, sqString, hashComment]

        case "swift":
            let kw = Rule(#"\b(?:var|let|func|class|struct|enum|protocol|extension|import|if|else|for|while|switch|case|return|true|false|nil|guard|defer|do|catch|throw|throws|init|deinit|self|super|override|final|static|public|private|internal|open|fileprivate|mutating|lazy|weak|unowned|required|convenience|inout|typealias|associatedtype|where|async|await|actor|some|any|in|is|as|break|continue|default|repeat|try|get|set|willSet|didSet|nonisolated)\b"#, tc.keyword)
            return [numbers, kw, pascal, dqString, slashLine, blockComment]

        case "javascript", "js":
            let kw = Rule(#"\b(?:var|let|const|function|class|if|else|for|while|do|switch|case|break|continue|return|throw|try|catch|finally|new|delete|typeof|instanceof|in|of|void|import|export|default|from|async|await|true|false|null|undefined|this|super)\b"#, tc.keyword)
            let tmpl = Rule(#"`(?:[^`\\]|\\.)*`"#, tc.string)
            return [numbers, kw, pascal, tmpl, dqString, sqString, slashLine, blockComment]

        case "typescript", "ts":
            let kw = Rule(#"\b(?:var|let|const|function|class|if|else|for|while|do|switch|case|break|continue|return|throw|try|catch|finally|new|delete|typeof|instanceof|in|of|void|import|export|default|from|async|await|true|false|null|undefined|this|super|type|interface|enum|implements|extends|abstract|readonly|namespace|declare|as|is|keyof|infer|never|unknown|any)\b"#, tc.keyword)
            let tmpl = Rule(#"`(?:[^`\\]|\\.)*`"#, tc.string)
            return [numbers, kw, pascal, tmpl, dqString, sqString, slashLine, blockComment]

        case "sql":
            let kw = Rule(#"\b(?:SELECT|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|CROSS|FULL|ON|GROUP|ORDER|BY|HAVING|INSERT|INTO|UPDATE|SET|DELETE|CREATE|ALTER|DROP|TABLE|INDEX|VIEW|DATABASE|SCHEMA|PRIMARY|KEY|FOREIGN|REFERENCES|NOT|NULL|UNIQUE|DEFAULT|DISTINCT|AS|AND|OR|IN|LIKE|BETWEEN|EXISTS|LIMIT|OFFSET|UNION|ALL|CASE|WHEN|THEN|ELSE|END|VALUES|WITH|RETURNING|CASCADE|CONSTRAINT|CHECK|BOOLEAN|INTEGER|VARCHAR|TEXT|FLOAT|DOUBLE|DATE|TIMESTAMP|BIGINT|SMALLINT|DECIMAL|NUMERIC|SERIAL|COUNT|SUM|AVG|MIN|MAX|COALESCE|CAST|OVER|PARTITION|RANK)\b"#, tc.keyword, options: [.dotMatchesLineSeparators, .caseInsensitive])
            let dashComment = Rule(#"--[^\n]*"#, tc.comment)
            return [numbers, kw, sqString, dashComment, blockComment]

        case "html":
            let tag  = Rule(#"</?[a-zA-Z][a-zA-Z0-9]*"#,        tc.keyword)
            let attr = Rule(#"\b[a-zA-Z][a-zA-Z0-9-]*(?=\s*=)"#, tc.type_)
            let xmlC = Rule(#"<!--[\s\S]*?-->"#,                   tc.comment)
            return [tag, attr, dqString, sqString, xmlC]

        case "css":
            let sel   = Rule(#"[.#]?[a-zA-Z][a-zA-Z0-9_-]*(?=\s*[{,])"#, tc.function_)
            let prop  = Rule(#"[a-zA-Z-]+(?=\s*:)"#,                        tc.keyword)
            let colVal = Rule(#"#[0-9a-fA-F]{3,8}\b"#,                      tc.number)
            return [colVal, numbers, sel, prop, dqString, sqString, blockComment]

        case "bash", "sh", "shell", "zsh":
            let kw  = Rule(#"\b(?:if|then|else|elif|fi|for|while|do|done|case|esac|function|return|echo|export|cd|ls|grep|awk|sed|chmod|sudo|exit|source|readonly|local|declare|unset|shift|trap|true|false|test|in|set)\b"#, tc.keyword)
            let variable = Rule(#"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"#, tc.function_)
            return [numbers, kw, variable, dqString, sqString, hashComment]

        case "rust":
            let kw = Rule(#"\b(?:fn|let|mut|struct|enum|impl|trait|for|while|if|else|match|use|mod|pub|crate|super|self|return|break|continue|loop|type|const|static|unsafe|where|async|await|move|ref|in|dyn|true|false|as|i8|i16|i32|i64|i128|u8|u16|u32|u64|u128|f32|f64|bool|char|usize|isize|str)\b"#, tc.keyword)
            let charLit = Rule(#"'[^'\\]'|'\\[nrt\\'"0]'"#, tc.string)
            return [numbers, kw, pascal, charLit, dqString, slashLine, blockComment]

        case "go", "golang":
            let kw = Rule(#"\b(?:func|var|const|type|struct|interface|package|import|if|else|for|return|break|continue|switch|case|default|defer|go|select|chan|map|make|new|nil|true|false|range|fallthrough|goto|error|string|int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|float32|float64|bool|byte|rune|uintptr|append|len|cap|delete|copy|close|panic|recover)\b"#, tc.keyword)
            let rawStr = Rule(#"`[^`]*`"#, tc.string)
            return [numbers, kw, pascal, rawStr, dqString, slashLine, blockComment]

        default:
            return [numbers, pascal, dqString, sqString, slashLine, hashComment, blockComment]
        }
    }
}
