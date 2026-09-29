//
//  TrackPersistenceService.swift
//  B-Side
//

import Foundation
import SwiftData

@MainActor
final class TrackPersistenceService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func findTrack(assetID: String) -> SavedTrack? {
        let requestedID = assetID
        let descriptor = FetchDescriptor<SavedTrack>(
            predicate: #Predicate { $0.assetID == requestedID }
        )
        return try? context.fetch(descriptor).first
    }

    func fetchAll() -> [SavedTrack] {
        let descriptor = FetchDescriptor<SavedTrack>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchAllMetadata() -> [Track] {
        fetchAll()
            .filter { !$0.isExcluded }
            .map(Self.makeTrack)
    }

    func allAssetIDs() -> Set<String> {
        Set(fetchAll().map(\.assetID))
    }

    func allCategoryNames() -> [String] {
        var canonicalNames: [String: String] = [:]

        for track in fetchAll() where !track.isExcluded {
            let displayName = CategoryNameNormalizer
                .normalizedDisplayName(track.categoryName)
            let key = CategoryNameNormalizer.comparisonKey(for: displayName)
            canonicalNames[key, default: displayName] = displayName
        }

        return canonicalNames.values.sorted()
    }

    func saveAnalysis(
        assetID: String,
        createdAt: Date,
        analysis: ScreenshotAnalysis
    ) {
        let categoryName = CategoryNameNormalizer
            .normalizedDisplayName(analysis.categoryName)

        if let existing = findTrack(assetID: assetID) {
            existing.title = analysis.title
            existing.rediscoveryDescription = analysis.rediscoveryDescription
            existing.detailDescription = analysis.detailDescription
            existing.tagsText = analysis.tags.joined(separator: "|||")
            existing.categoryName = categoryName
            existing.isExcluded = false
        } else {
            context.insert(
                SavedTrack(
                    assetID: assetID,
                    createdAt: createdAt,
                    title: analysis.title,
                    rediscoveryDescription: analysis.rediscoveryDescription,
                    detailDescription: analysis.detailDescription,
                    tags: analysis.tags,
                    categoryName: categoryName
                )
            )
        }

        saveContext()
    }

    func save(track: Track) {
        guard let title = track.title,
              let rediscoveryDescription = track.rediscoveryDescription,
              let detailDescription = track.detailDescription,
              let categoryName = track.categoryName
        else {
            return
        }

        let normalizedCategory = CategoryNameNormalizer
            .normalizedDisplayName(categoryName)

        if let existing = findTrack(assetID: track.id) {
            existing.title = title
            existing.rediscoveryDescription = rediscoveryDescription
            existing.detailDescription = detailDescription
            existing.tagsText = track.tags.joined(separator: "|||")
            existing.categoryName = normalizedCategory
        } else {
            context.insert(
                SavedTrack(
                    assetID: track.id,
                    createdAt: track.createdAt,
                    title: title,
                    rediscoveryDescription: rediscoveryDescription,
                    detailDescription: detailDescription,
                    tags: track.tags,
                    categoryName: normalizedCategory
                )
            )
        }

        saveContext()
    }

    func exclude(assetID: String) {
        guard let saved = findTrack(assetID: assetID) else {
            return
        }

        saved.isExcluded = true
        saveContext()
    }

    private static func makeTrack(from saved: SavedTrack) -> Track {
        Track(
            id: saved.assetID,
            createdAt: saved.createdAt,
            title: saved.title,
            rediscoveryDescription: saved.rediscoveryDescription,
            detailDescription: saved.detailDescription,
            tags: saved.tags,
            categoryName: CategoryNameNormalizer
                .normalizedDisplayName(saved.categoryName)
        )
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ SwiftData save failed:", error)
        }
    }
}
