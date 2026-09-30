//
//  CategoryMigrationService.swift
//  B-Side
//

import Foundation
import SwiftData

enum CategoryNameNormalizer {
    private static let legacyNames: [String: String] = [
        "thingstobuy": "Things to Buy",
        "placestovisit": "Places to Visit",
        "designinspiration": "Design Inspiration",
        "food": "Food",
        "events": "Events",
        "conversations": "Conversations",
        "workstudy": "Work & Study",
        "travel": "Travel",
        "memesfun": "Memes & Fun",
        "readlater": "Read Later"
    ]

    static func normalizedDisplayName(_ name: String) -> String {
        let trimmed = name
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        guard !trimmed.isEmpty else {
            return "Uncategorized"
        }

        let legacyKey = trimmed
            .filter { $0.isLetter || $0.isNumber }
            .lowercased()

        return legacyNames[legacyKey] ?? trimmed
    }

    static func comparisonKey(for name: String) -> String {
        normalizedDisplayName(name)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .lowercased()
    }

    static func preferredDisplayName(_ first: String, _ second: String) -> String {
        displayScore(second) > displayScore(first) ? second : first
    }

    private static func displayScore(_ name: String) -> Int {
        let hasUppercase = name.contains(where: \.isUppercase)
        let hasLowercase = name.contains(where: \.isLowercase)
        return (hasUppercase ? 1 : 0) + (hasLowercase ? 1 : 0)
    }
}

@MainActor
final class CategoryMigrationService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func migrateLegacyCategoryNames() {
        let descriptor = FetchDescriptor<SavedTrack>()

        guard let savedTracks = try? context.fetch(descriptor) else {
            return
        }

        var changed = false
        var canonicalNames: [String: String] = [:]

        for track in savedTracks {
            let normalized = CategoryNameNormalizer
                .normalizedDisplayName(track.categoryName)
            let key = CategoryNameNormalizer.comparisonKey(for: normalized)
            canonicalNames[key] = canonicalNames[key].map {
                CategoryNameNormalizer.preferredDisplayName($0, normalized)
            } ?? normalized
        }

        for track in savedTracks {
            let normalized = CategoryNameNormalizer
                .normalizedDisplayName(track.categoryName)
            let key = CategoryNameNormalizer.comparisonKey(for: normalized)
            let canonical = canonicalNames[key] ?? normalized

            if canonical != track.categoryName {
                track.categoryName = canonical
                changed = true
            }
        }

        if changed {
            try? context.save()
        }
    }
}
