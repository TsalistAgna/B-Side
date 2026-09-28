//
//  CollectionOrganizer.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import FoundationModels

@Generable
struct CollectionMatch {

    @Guide(
        description:
        """
        True if this Track meaningfully belongs
        in the requested collection.
        """
    )
    var matches: Bool
}

@available(iOS 27.0, *)
final class CollectionOrganizer {

    private let model =
        SystemLanguageModel.default


    func matches(
        track: Track,
        collectionName: String
    ) async throws -> Bool {

        guard model.isAvailable else {
            return false
        }


        let session =
            LanguageModelSession(
                model: model,
                instructions: """
                Decide whether a screenshot Track
                meaningfully belongs in a user-created
                collection.

                Be selective.

                Do not match something simply because
                there is a weak keyword overlap.
                """
            )


        let trackContext = """

        Collection:
        \(collectionName)

        Track title:
        \(track.title ?? "Unknown")

        Category:
        \(track.category?.title ?? "Unknown")

        Description:
        \(track.detailDescription ?? "Unknown")

        Tags:
        \(track.tags.joined(separator: ", "))

        """


        let response =
            try await session.respond(
                to: trackContext,
                generating:
                    CollectionMatch.self
            )


        return response.content.matches
    }
}
