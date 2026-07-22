//
//  SyntaxHighlighter.swift
//  Nook
//

import SwiftUI
import AppKit

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
        case .xcodeLight:
            return .init(plain: Color(hex: "1F2024"), keyword: Color(hex: "AD3DA4"),
                         string: Color(hex: "D12F1B"), comment: Color(hex: "5D6C79"),
                         number: Color(hex: "272AD8"), function_: Color(hex: "3900A0"),
                         type_: Color(hex: "703DAA"))
        case .githubLight:
            return .init(plain: Color(hex: "1F2328"), keyword: Color(hex: "CF222E"),
                         string: Color(hex: "0A3069"), comment: Color(hex: "6E7781"),
                         number: Color(hex: "0550AE"), function_: Color(hex: "8250DF"),
                         type_: Color(hex: "953800"))
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

    // Kompilierte Regexes cachen – vermeidet Neukompilierung bei jedem Keystroke
    private static var regexCache = [String: NSRegularExpression]()
    private static func compiledRegex(pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? {
        let key = "\(options.rawValue):\(pattern)"
        if let cached = regexCache[key] { return cached }
        guard let r = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        regexCache[key] = r
        return r
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

    /// Wendet Syntax-Highlighting direkt auf einen NSTextStorage an (für NSTextView-Editor).
    /// Ersetzt nur Attribute — der Textinhalt bleibt unverändert, Undo-History bleibt erhalten.
    static func applyHighlightingInPlace(storage: NSTextStorage, code: String, language: String, theme: SyntaxTheme, fontSize: Double) {
        guard storage.length == (code as NSString).length else { return }
        let tc = theme.tokenColors
        let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        let fullRange = NSRange(location: 0, length: storage.length)

        storage.beginEditing()
        storage.setAttributes([.font: font, .foregroundColor: NSColor(tc.plain)], range: fullRange)

        for rule in rules(for: language.lowercased(), tc: tc) {
            guard let regex = compiledRegex(pattern: rule.pattern, options: rule.options) else { continue }
            let nsRange = NSRange(code.startIndex..., in: code)
            for match in regex.matches(in: code, range: nsRange) {
                storage.addAttribute(.foregroundColor, value: NSColor(rule.color), range: match.range)
            }
        }
        storage.endEditing()
    }

    private static func applyRule(_ rule: Rule, to result: inout AttributedString, in code: String) {
        guard let regex = compiledRegex(pattern: rule.pattern, options: rule.options) else { return }
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

    // MARK: - Language rules
    // Reihenfolge = Priorität (spätere Regeln überschreiben frühere):
    // pascal → kw → blockComment → strings → lineComment
    //
    // Wichtig: slashLine nutzt (?<!:) damit "https://..." korrekt als String bleibt.

    private static func rules(for lang: String, tc: SyntaxTheme.TokenColors) -> [Rule] {
        // Gemeinsame Bausteine
        let numbers      = Rule(#"\b0x[0-9a-fA-F]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#, tc.number)
        let pascal       = Rule(#"\b[A-Z][A-Za-z0-9_]*\b"#, tc.type_)
        // Negative lookbehind (?<!:) verhindert Match bei "https://..." URLs
        let slashLine    = Rule(#"(?<!:)//[^\n]*"#,   tc.comment)
        let blockComment = Rule(#"/\*[\s\S]*?\*/"#,   tc.comment)
        let hashComment  = Rule(#"(?<!&)#[^\n]*"#,    tc.comment)
        let dashComment  = Rule(#"--[^\n]*"#,          tc.comment)
        let dqString     = Rule(#""(?:[^"\\]|\\.)*""#, tc.string)
        let sqString     = Rule(#"'(?:[^'\\]|\\.)*'"#, tc.string)
        let tmplString   = Rule(#"`(?:[^`\\]|\\.)*`"#, tc.string)
        let xmlComment   = Rule(#"<!--[\s\S]*?-->"#,   tc.comment)

        switch lang {

        // MARK: Python
        case "python":
            let kw  = Rule(#"\b(?:False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield|print|len|range|self|super|type)\b"#, tc.keyword)
            let doc = Rule(#"\"\"\"[\s\S]*?\"\"\"|'''[\s\S]*?'''"#, tc.string)
            // pascal vor kw: Keywords (True/False/None) überschreiben PascalCase-Einfärbung
            return [numbers, pascal, kw, doc, dqString, sqString, hashComment]

        // MARK: Swift
        case "swift":
            let kw = Rule(#"\b(?:var|let|func|class|struct|enum|protocol|extension|import|if|else|for|while|switch|case|return|true|false|nil|guard|defer|do|catch|throw|throws|init|deinit|self|super|override|final|static|public|private|internal|open|fileprivate|mutating|lazy|weak|unowned|required|convenience|inout|typealias|associatedtype|where|async|await|actor|some|any|in|is|as|break|continue|default|repeat|try|get|set|willSet|didSet|nonisolated|consuming|borrowing)\b"#, tc.keyword)
            let multiStr = Rule(#"\"\"\"[\s\S]*?\"\"\""#, tc.string)
            return [numbers, pascal, kw, blockComment, multiStr, dqString, slashLine]

        // MARK: JavaScript
        case "javascript", "js":
            let kw = Rule(#"\b(?:var|let|const|function|class|if|else|for|while|do|switch|case|break|continue|return|throw|try|catch|finally|new|delete|typeof|instanceof|in|of|void|import|export|default|from|async|await|true|false|null|undefined|this|super|get|set|static|extends|yield|debugger)\b"#, tc.keyword)
            return [numbers, pascal, kw, blockComment, tmplString, dqString, sqString, slashLine]

        // MARK: TypeScript
        case "typescript", "ts":
            let kw = Rule(#"\b(?:var|let|const|function|class|if|else|for|while|do|switch|case|break|continue|return|throw|try|catch|finally|new|delete|typeof|instanceof|in|of|void|import|export|default|from|async|await|true|false|null|undefined|this|super|type|interface|enum|implements|extends|abstract|readonly|namespace|declare|as|is|keyof|infer|never|unknown|any|string|number|boolean|object|bigint|symbol|get|set|static|override|satisfies)\b"#, tc.keyword)
            return [numbers, pascal, kw, blockComment, tmplString, dqString, sqString, slashLine]

        // MARK: JSX / React
        case "jsx", "react", "tsx":
            let kw      = Rule(#"\b(?:var|let|const|function|class|if|else|for|while|return|import|export|default|from|async|await|true|false|null|undefined|this|new|typeof|instanceof|of|in|void|throw|try|catch|finally|delete|extends|static|super|yield|string|number|boolean|type|interface)\b"#, tc.keyword)
            let jsxTag  = Rule(#"</?[A-Za-z][A-Za-z0-9.]*"#, tc.function_)
            let jsxAttr = Rule(#"\b[a-zA-Z][a-zA-Z0-9-]*(?=\s*=\s*[{"'])"#, tc.type_)
            return [numbers, pascal, kw, blockComment, tmplString, dqString, sqString, jsxTag, jsxAttr, slashLine]

        // MARK: Vue
        case "vue":
            let kw        = Rule(#"\b(?:var|let|const|function|if|else|for|return|export|default|import|from|async|await|true|false|null|undefined|new|class|type|interface)\b"#, tc.keyword)
            let tag       = Rule(#"</?[a-zA-Z][a-zA-Z0-9-]*"#, tc.function_)
            let directive = Rule(#"v-[a-z][a-z0-9-]*|@[a-z][a-z0-9-]*|:[a-z][a-z0-9-]*"#, tc.type_)
            return [numbers, pascal, kw, xmlComment, blockComment, tmplString, dqString, sqString, tag, directive, slashLine]

        // MARK: Kotlin
        case "kotlin", "kt":
            let kw = Rule(#"\b(?:fun|val|var|class|object|interface|if|else|for|while|when|return|import|package|as|is|in|this|super|null|true|false|companion|data|sealed|abstract|override|private|public|internal|protected|open|final|lateinit|suspend|by|constructor|init|get|set|throw|try|catch|finally|break|continue|it|typealias|reified|inline|infix|operator|crossinline|noinline|vararg|out|dynamic|enum|annotation)\b"#, tc.keyword)
            return [numbers, pascal, kw, blockComment, dqString, sqString, slashLine]

        // MARK: Java
        case "java":
            let kw  = Rule(#"\b(?:public|private|protected|static|final|abstract|class|interface|extends|implements|import|package|new|return|if|else|for|while|do|switch|case|break|continue|throw|throws|try|catch|finally|this|super|null|true|false|void|int|long|float|double|boolean|char|byte|short|String|Object|enum|default|synchronized|volatile|transient|native|assert|instanceof|var|record|sealed|permits)\b"#, tc.keyword)
            let ann = Rule(#"@[A-Za-z][A-Za-z0-9]*\b"#, tc.function_)
            return [numbers, pascal, kw, ann, blockComment, dqString, sqString, slashLine]

        // MARK: C
        case "c":
            let kw      = Rule(#"\b(?:int|long|short|char|unsigned|signed|float|double|void|struct|union|enum|typedef|const|static|extern|register|auto|volatile|inline|return|if|else|for|while|do|switch|case|break|continue|goto|sizeof|NULL|true|false|bool|size_t|ssize_t|uint8_t|uint16_t|uint32_t|uint64_t|int8_t|int16_t|int32_t|int64_t)\b"#, tc.keyword)
            let preDir  = Rule(#"#\s*(?:include|define|ifdef|ifndef|endif|pragma|undef|if|elif|else|error|warning)\b[^\n]*"#, tc.type_)
            let sysInc  = Rule(#"<[A-Za-z_][A-Za-z0-9_./]*\.h>"#, tc.string)
            return [numbers, pascal, kw, preDir, sysInc, blockComment, dqString, sqString, slashLine]

        // MARK: C++
        case "cpp", "c++", "cxx":
            let kw      = Rule(#"\b(?:int|long|short|char|unsigned|signed|float|double|void|bool|struct|class|union|enum|typedef|const|static|extern|auto|volatile|inline|return|if|else|for|while|do|switch|case|break|continue|goto|sizeof|nullptr|NULL|true|false|new|delete|public|private|protected|virtual|override|final|explicit|operator|template|typename|namespace|using|constexpr|consteval|constinit|decltype|noexcept|mutable|friend|this|co_await|co_return|co_yield|requires|concept)\b"#, tc.keyword)
            let preDir  = Rule(#"#\s*(?:include|define|ifdef|ifndef|endif|pragma|undef|if|elif|else|error|warning)\b[^\n]*"#, tc.type_)
            let sysInc  = Rule(#"<[A-Za-z_][A-Za-z0-9_./]*>"#, tc.string)
            return [numbers, pascal, kw, preDir, sysInc, blockComment, dqString, sqString, slashLine]

        // MARK: C#
        case "csharp", "cs", "c#":
            let kw  = Rule(#"\b(?:var|int|long|float|double|decimal|bool|char|string|object|void|class|struct|interface|enum|delegate|namespace|using|public|private|protected|internal|static|readonly|const|abstract|virtual|override|sealed|new|return|if|else|for|foreach|while|do|switch|case|break|continue|throw|try|catch|finally|null|true|false|this|base|async|await|in|out|ref|params|get|set|add|remove|value|typeof|sizeof|nameof|is|as|checked|unchecked|lock|fixed|unsafe|record|init|required|with|and|or|not|when|nint|nuint)\b"#, tc.keyword)
            let ann = Rule(#"\[[A-Za-z][A-Za-z0-9]*(?:\([^)]*\))?\]"#, tc.function_)
            return [numbers, pascal, kw, ann, blockComment, dqString, sqString, slashLine]

        // MARK: Ruby
        case "ruby", "rb":
            let kw     = Rule(#"\b(?:def|class|module|end|if|else|elsif|unless|then|case|when|while|until|for|do|begin|rescue|ensure|raise|return|yield|require|require_relative|include|extend|prepend|attr_reader|attr_writer|attr_accessor|initialize|self|super|nil|true|false|puts|print|p|pp|and|or|not|in|next|break|redo|retry|lambda|proc|new|freeze|frozen)\b"#, tc.keyword)
            let symbol = Rule(#":[a-zA-Z_][a-zA-Z0-9_]*"#, tc.type_)
            let interp = Rule(#"#\{[^}]*\}"#, tc.function_)
            let heredoc = Rule(#"<<[~-]?['"]?\w+['"]?[\s\S]*?\n\w+"#, tc.string)
            return [numbers, pascal, kw, symbol, heredoc, dqString, sqString, interp, hashComment]

        // MARK: PHP
        case "php":
            let kw       = Rule(#"\b(?:echo|print|function|class|interface|abstract|extends|implements|namespace|use|return|if|else|elseif|foreach|while|for|switch|case|break|continue|default|new|null|true|false|this|self|parent|static|public|private|protected|final|try|catch|finally|throw|require|include|require_once|include_once|array|list|match|fn|readonly|enum|const|var|yield|from|instanceof)\b"#, tc.keyword)
            let variable = Rule(#"\$[A-Za-z_][A-Za-z0-9_]*"#, tc.function_)
            let phpTag   = Rule(#"<\?php|<\?=|\?>"#, tc.type_)
            let htmlTag  = Rule(#"</?[a-zA-Z][a-zA-Z0-9-]*"#, tc.keyword)
            let ann      = Rule(#"#\[[A-Za-z][A-Za-z0-9\\\,\s\"']*\]"#, tc.function_)
            return [numbers, pascal, kw, phpTag, htmlTag, variable, ann, blockComment, dqString, sqString, slashLine]

        // MARK: Dart
        case "dart":
            let kw = Rule(#"\b(?:var|final|const|dynamic|void|int|double|num|bool|String|class|extends|implements|mixin|with|abstract|get|set|return|if|else|for|while|do|switch|case|break|continue|new|null|true|false|this|super|is|as|in|throw|try|catch|finally|rethrow|async|await|import|export|library|part|show|hide|typedef|required|late|factory|external|enum|on|covariant|sealed|base|interface|when)\b"#, tc.keyword)
            return [numbers, pascal, kw, blockComment, dqString, sqString, slashLine]

        // MARK: Go
        case "go", "golang":
            let kw    = Rule(#"\b(?:func|var|const|type|struct|interface|package|import|if|else|for|return|break|continue|switch|case|default|defer|go|select|chan|map|make|new|nil|true|false|range|fallthrough|goto|error|string|int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|float32|float64|complex64|complex128|bool|byte|rune|uintptr|append|len|cap|delete|copy|close|panic|recover|print|println)\b"#, tc.keyword)
            let rawStr = Rule(#"`[^`]*`"#, tc.string)
            return [numbers, pascal, kw, blockComment, rawStr, dqString, slashLine]

        // MARK: Rust
        case "rust":
            let kw      = Rule(#"\b(?:fn|let|mut|struct|enum|impl|trait|for|while|if|else|match|use|mod|pub|crate|super|self|return|break|continue|loop|type|const|static|unsafe|where|async|await|move|ref|in|dyn|true|false|as|i8|i16|i32|i64|i128|u8|u16|u32|u64|u128|f32|f64|bool|char|usize|isize|str|String|Vec|Box|Option|Result|Some|None|Ok|Err|Self)\b"#, tc.keyword)
            let charLit = Rule(#"b?'(?:[^'\\]|\\.)'|b?'\\(?:x[0-9a-fA-F]{2}|u\{[0-9a-fA-F]+\}|[nrt'\\0])'"#, tc.string)
            let macro_  = Rule(#"\b[a-z_][a-z0-9_]*!"#, tc.function_)
            let lifetime = Rule(#"'[a-z_][a-z0-9_]*\b"#, tc.type_)
            return [numbers, pascal, kw, lifetime, blockComment, charLit, dqString, macro_, slashLine]

        // MARK: SQL
        case "sql":
            let kw = Rule(#"\b(?:SELECT|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|CROSS|FULL|ON|GROUP|ORDER|BY|HAVING|INSERT|INTO|UPDATE|SET|DELETE|CREATE|ALTER|DROP|TABLE|INDEX|VIEW|DATABASE|SCHEMA|PRIMARY|FOREIGN|KEY|REFERENCES|NOT|NULL|UNIQUE|DEFAULT|DISTINCT|AS|AND|OR|IN|LIKE|ILIKE|BETWEEN|EXISTS|LIMIT|OFFSET|UNION|ALL|CASE|WHEN|THEN|ELSE|END|VALUES|WITH|RETURNING|CASCADE|CONSTRAINT|CHECK|BOOLEAN|INTEGER|INT|VARCHAR|TEXT|FLOAT|DOUBLE|DATE|TIMESTAMP|BIGINT|SMALLINT|DECIMAL|NUMERIC|SERIAL|CHAR|BINARY|JSON|JSONB|UUID|COUNT|SUM|AVG|MIN|MAX|COALESCE|NULLIF|CAST|CONVERT|OVER|PARTITION|RANK|ROW_NUMBER|DENSE_RANK|WINDOW|TRIGGER|FUNCTION|PROCEDURE|BEGIN|COMMIT|ROLLBACK|TRANSACTION|SAVEPOINT|EXPLAIN|ANALYZE)\b"#, tc.keyword, options: [.dotMatchesLineSeparators, .caseInsensitive])
            let sqlStr = Rule(#"'(?:[^'\\]|\\.)*'"#, tc.string)
            let ident  = Rule(#""[^"]+""#, tc.type_)
            return [numbers, kw, sqlStr, ident, dashComment, blockComment]

        // MARK: JSON
        case "json":
            let key     = Rule(#""[^"\n]+"(?=\s*:)"#, tc.keyword)
            let special = Rule(#"\b(?:true|false|null)\b"#, tc.type_)
            let strVal  = Rule(#""(?:[^"\\]|\\.)*""#, tc.string)
            return [numbers, special, key, strVal]

        // MARK: YAML
        case "yaml", "yml":
            let key     = Rule(#"^[ \t]*[A-Za-z_][A-Za-z0-9_-]*(?=\s*:)"#, tc.keyword, options: [.dotMatchesLineSeparators, .anchorsMatchLines])
            let anchor  = Rule(#"[&*][A-Za-z_][A-Za-z0-9_]*"#, tc.type_)
            let special = Rule(#"\b(?:true|false|null|yes|no|on|off|True|False|Null|YES|NO|ON|OFF)\b"#, tc.function_)
            let multiline = Rule(#"[|>][-+]?[ \t]*\n(?:[ \t]+[^\n]*\n?)+"#, tc.string)
            return [numbers, special, anchor, multiline, key, dqString, sqString, hashComment]

        // MARK: HTML / XML
        case "html", "xml":
            let tag      = Rule(#"</?[a-zA-Z][a-zA-Z0-9:-]*"#, tc.keyword)
            let attr     = Rule(#"\b[a-zA-Z][a-zA-Z0-9:-]*(?=\s*=)"#, tc.type_)
            let entity   = Rule(#"&[a-zA-Z][a-zA-Z0-9]*;|&#\d+;"#, tc.function_)
            let doctype  = Rule(#"<!DOCTYPE[^>]*>"#, tc.comment)
            return [xmlComment, doctype, tag, attr, entity, dqString, sqString]

        // MARK: CSS
        case "css", "scss", "less":
            let colVal   = Rule(#"#[0-9a-fA-F]{3,8}\b"#, tc.number)
            let unit     = Rule(#"\b\d+(?:\.\d+)?(?:px|em|rem|vh|vw|vmin|vmax|%|pt|pc|ex|ch|fr|deg|rad|turn|ms|s)\b"#, tc.number)
            let variable = Rule(#"--[a-zA-Z][a-zA-Z0-9-]*|@[a-zA-Z][a-zA-Z0-9-]*|\$[a-zA-Z][a-zA-Z0-9-]*"#, tc.function_)
            let sel      = Rule(#"[.#]?[a-zA-Z][a-zA-Z0-9_-]*(?=\s*\{)"#, tc.type_)
            let prop     = Rule(#"(?:^|;|\{)[ \t]*[a-zA-Z][a-zA-Z0-9-]*(?=\s*:)"#, tc.keyword, options: [.dotMatchesLineSeparators, .anchorsMatchLines])
            let pseudo   = Rule(#"::?[a-zA-Z][a-zA-Z0-9-]*"#, tc.function_)
            return [colVal, unit, numbers, blockComment, variable, sel, prop, pseudo, dqString, sqString]

        // MARK: Bash / Shell
        case "bash", "sh", "shell", "zsh", "fish":
            let kw       = Rule(#"\b(?:if|then|else|elif|fi|for|while|do|done|case|esac|function|return|echo|export|cd|ls|grep|awk|sed|chmod|sudo|exit|source|readonly|local|declare|typeset|unset|shift|trap|true|false|test|in|set|read|printf|mkdir|rm|cp|mv|cat|head|tail|find|sort|curl|wget|git|npm|yarn|pip|python|python3|ruby|node)\b"#, tc.keyword)
            let variable = Rule(#"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?|\$[0-9@#?$!*-]"#, tc.function_)
            let flag     = Rule(#"(?<=\s)-{1,2}[a-zA-Z][a-zA-Z0-9-]*"#, tc.type_)
            return [numbers, kw, variable, flag, dqString, sqString, hashComment]

        // MARK: Markdown
        case "markdown", "md":
            let heading   = Rule(#"^#{1,6}[ \t]+[^\n]*"#, tc.keyword, options: [.dotMatchesLineSeparators, .anchorsMatchLines])
            let codeBlock = Rule(#"```[\s\S]*?```|~~~[\s\S]*?~~~"#, tc.string)
            let inlineCode = Rule(#"`[^`\n]+`"#, tc.string)
            let bold      = Rule(#"\*\*[^\*\n]+\*\*|__[^_\n]+__"#, tc.function_)
            let italic    = Rule(#"(?<!\*)\*[^\*\n]+\*(?!\*)|(?<!_)_[^_\n]+_(?!_)"#, tc.type_)
            let link      = Rule(#"\[[^\]]+\]\([^\)]+\)"#, tc.function_)
            let blockquote = Rule(#"^>[ \t]*[^\n]*"#, tc.comment, options: [.dotMatchesLineSeparators, .anchorsMatchLines])
            return [heading, codeBlock, inlineCode, bold, italic, link, blockquote]

        // MARK: Default
        default:
            return [numbers, pascal, dqString, sqString, slashLine, hashComment, blockComment]
        }
    }
}
