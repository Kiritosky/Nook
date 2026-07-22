//
//  SpotlightManager.swift
//  Nook
//

import CoreSpotlight
import UniformTypeIdentifiers

enum SpotlightManager {
    static func indexAll(_ snippets: [Snippet]) {
        let items = snippets.map { searchableItem(for: $0) }
        CSSearchableIndex.default().indexSearchableItems(items) { _ in }
    }

    static func index(_ snippet: Snippet) {
        CSSearchableIndex.default().indexSearchableItems([searchableItem(for: snippet)]) { _ in }
    }

    static func remove(_ snippet: Snippet) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [snippet.spotlightIdentifier]
        ) { _ in }
    }

    static func removeAll() {
        CSSearchableIndex.default().deleteAllSearchableItems { _ in }
    }

    private static func searchableItem(for snippet: Snippet) -> CSSearchableItem {
        let attr = CSSearchableItemAttributeSet(contentType: .sourceCode)
        attr.title = snippet.title
        attr.contentDescription = [snippet.effectiveLanguageName, snippet.topic]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        attr.keywords = snippet.tags + [snippet.effectiveLanguageName, snippet.topic, snippet.project ?? ""]
        attr.textContent = String(snippet.code.prefix(500))

        return CSSearchableItem(
            uniqueIdentifier: snippet.spotlightIdentifier,
            domainIdentifier: "dev.nook.snippets",
            attributeSet: attr
        )
    }
}
