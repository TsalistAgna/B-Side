//
//  TrackPersistenceService.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 18/09/26.
//

import Foundation
import SwiftData

@MainActor
final class TrackPersistenceService {

    private let context: ModelContext


    init(context: ModelContext) {

        self.context = context
    }


    // MARK: - Find Saved Track

    func findTrack(
        assetID: String
    ) -> SavedTrack? {

        let descriptor =
            FetchDescriptor<SavedTrack>(
                predicate: #Predicate {
                    $0.assetID == assetID
                }
            )

        return try? context
            .fetch(descriptor)
            .first
    }


    // MARK: - Save AI Result

    func save(
        track: Track
    ) {

        guard
            let title = track.title,
            let rediscovery =
                track.rediscoveryDescription,
            let detail =
                track.detailDescription,
            let category =
                track.category
        else {
            return
        }


        // Already saved?
        if let existing =
            findTrack(
                assetID: track.id
            ) {

            existing.title = title
            existing.rediscoveryDescription =
                rediscovery

            existing.detailDescription =
                detail

            existing.tagsText =
                track.tags.joined(
                    separator: "|||"
                )

            existing.categoryName =
                category.storageName

        } else {

            let savedTrack = SavedTrack(
                assetID: track.id,
                createdAt:
                    track.createdAt,
                title: title,
                rediscoveryDescription:
                    rediscovery,
                detailDescription:
                    detail,
                tags:
                    track.tags,
                categoryName:
                    category.storageName
            )

            context.insert(savedTrack)
        }


        try? context.save()
    }


    // MARK: - Delete From B-Side

    func exclude(
        assetID: String
    ) {

        guard let saved =
            findTrack(assetID: assetID)
        else {
            return
        }

        saved.isExcluded = true

        try? context.save()
    }
}
