//
//  TrackPersistenceService.swift
//  B-Side
//

import Foundation
import SwiftData
import OSLog

@MainActor
final class TrackPersistenceService {
    private let context: ModelContext
    var commitOverride: (() throws -> Void)?

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
            canonicalNames[key] = canonicalNames[key].map {
                CategoryNameNormalizer.preferredDisplayName($0, displayName)
            } ?? displayName
        }

        return canonicalNames.values.sorted()
    }

    func saveAnalysis(
        assetID: String,
        createdAt: Date,
        analysis: ScreenshotAnalysis
    ) throws {
        let categoryName = CategoryNameNormalizer
            .normalizedDisplayName(analysis.categoryName)

        if let existing = findTrack(assetID: assetID), existing.userEdited || existing.isExcluded {
            return
        }
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

        findTrack(assetID: assetID)?.analysisStatus = .completed
        try commit()
    }

    func save(track: Track) throws {
        let title = track.title
        let rediscoveryDescription = track.rediscoveryDescription
        let detailDescription = track.detailDescription
        let categoryName = track.categoryName ?? "Uncategorized"

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

        if let saved = findTrack(assetID: track.id) {
            saved.userEdited = true
            saved.analysisStatus = .manual
        }
        try commit()
    }

    func exclude(assetID: String) throws {
        if let saved = findTrack(assetID: assetID) { saved.isExcluded = true }
        else {
            let record = SavedTrack(assetID: assetID, createdAt: .now, title: nil, rediscoveryDescription: nil, detailDescription: nil, tags: [], categoryName: "Uncategorized", isExcluded: true)
            record.analysisStatus = .pending
            context.insert(record)
        }
        try commit()
    }

    func deleteAll() throws {
        let records = try context.fetch(FetchDescriptor<SavedTrack>())
        for track in records { context.delete(track) }
        try commit()
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

    func register(assetID: String, createdAt: Date) throws {
        guard findTrack(assetID: assetID) == nil else { return }
        let record = SavedTrack(assetID: assetID, createdAt: createdAt, title: nil, rediscoveryDescription: nil, detailDescription: nil, tags: [], categoryName: "Uncategorized")
        record.analysisStatus = .pending
        context.insert(record)
        try commit()
    }

    func markFailed(_ id: String) throws {
        guard let record = findTrack(assetID: id), !record.userEdited else { return }
        record.analysisStatus = .failed
        try commit()
    }

    private func commit() throws {
        do { if let commitOverride { try commitOverride() }; try context.save() }
        catch { context.rollback(); throw error }
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            Logger(subsystem: "Side-B", category: "Persistence").error("Local save failed")
        }
    }
}
