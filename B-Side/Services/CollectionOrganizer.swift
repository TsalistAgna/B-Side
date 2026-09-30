//
//  CollectionOrganizer.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import Foundation
import FoundationModels

enum CollectionOrganizerError: LocalizedError {
    case modelUnavailable

    var errorDescription: String? {
        "Apple Intelligence is unavailable right now."
    }
}

@Generable(description: "Tracks selected for a collection")
struct CollectionOrganization {
    @Guide(
        description: "Only IDs copied exactly from tracks that strongly belong in the requested collection"
    )
    var matchingTrackIDs: [String]
}

@available(iOS 27.0, *)
final class CollectionOrganizer {
    private let model = SystemLanguageModel.default

    func organize(
        tracks: [Track],
        collectionName: String
    ) async throws -> [String] {
        guard model.isAvailable else {
            throw CollectionOrganizerError.modelUnavailable
        }

        guard !tracks.isEmpty else {
            return []
        }

        var matchingIDs = Set<String>()

        for batchStart in stride(from: 0, to: tracks.count, by: 25) {
            let batch = Array(
                tracks[batchStart..<min(batchStart + 25, tracks.count)]
            )
            let batchMatches = try await organizeBatch(
                batch,
                collectionName: collectionName
            )
            matchingIDs.formUnion(batchMatches)
        }

        return Array(matchingIDs)
    }

    private func organizeBatch(
        _ tracks: [Track],
        collectionName: String
    ) async throws -> [String] {
        let session = LanguageModelSession(
            model: model,
            instructions: """
            You organize a personal screenshot library into meaningful collections.
            Select a Track only when its title, description, tags, and categoryName
            strongly match the requested collection's subject or purpose. Be selective.
            Never invent, alter, or omit characters from a Track ID.
            """
        )

        let trackContext = tracks.map { track in
            """
            ID: \(track.id)
            Title: \(track.title ?? "Unknown")
            Current collection: \(track.categoryName ?? "Uncategorized")
            Description: \(track.detailDescription ?? "Unknown")
            Tags: \(track.tags.joined(separator: ", "))
            """
        }
        .joined(separator: "\n---\n")

        let response = try await session.respond(
            to: """
            Requested collection: \(collectionName)

            Return the IDs of every supplied track that strongly belongs in this collection.
            Return an empty list when none belong.

            Tracks:
            \(trackContext)
            """,
            generating: CollectionOrganization.self
        )

        let validIDs = Set(tracks.map(\.id))
        return Array(
            Set(response.content.matchingTrackIDs)
                .intersection(validIDs)
        )
    }
}
