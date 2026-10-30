//
//  CollectionPersistenceService.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 29/09/26.
//

import Foundation
import SwiftData
import OSLog

@MainActor
final class CollectionPersistenceService {

    private let context:
        ModelContext


    init(
        context: ModelContext
    ) {

        self.context = context
    }


    // MARK: - READ

    func fetchAll()
    -> [CustomCollection] {

        let descriptor =
            FetchDescriptor<SavedCollection>(
                sortBy: [
                    SortDescriptor(
                        \.createdAt,
                        order: .reverse
                    )
                ]
            )


        guard let savedCollections =
            try? context.fetch(
                descriptor
            )
        else {
            return []
        }


        return savedCollections.map {
            saved in


            CustomCollection(
                id:
                    saved.id,

                name:
                    saved.name,

                vinylStyle:
                    VinylStyle(
                        rawValue:
                            saved
                                .vinylStyleName
                    ) ?? .pink,

                isAutoOrganized:
                    saved
                        .isAutoOrganized,

                trackIDs:
                    saved.trackIDs,

                createdAt:
                    saved.createdAt
            )
        }
    }


    // MARK: - FIND

    private func find(
        id: UUID
    ) -> SavedCollection? {

        let collectionID = id


        let descriptor =
            FetchDescriptor<SavedCollection>(
                predicate:
                    #Predicate {
                        $0.id ==
                            collectionID
                    }
            )


        return try? context
            .fetch(descriptor)
            .first
    }


    // MARK: - CREATE / UPDATE

    func save(
        _ collection:
            CustomCollection
    ) throws {

        if let existing =
            find(
                id:
                    collection.id
            ) {

            // UPDATE

            existing.name =
                collection.name

            existing.vinylStyleName =
                collection
                    .vinylStyle
                    .rawValue

            existing.isAutoOrganized =
                collection
                    .isAutoOrganized

            existing.trackIDs =
                collection.trackIDs

        } else {

            // CREATE

            let saved =
                SavedCollection(

                    id:
                        collection.id,

                    name:
                        collection.name,

                    vinylStyleName:
                        collection
                            .vinylStyle
                            .rawValue,

                    isAutoOrganized:
                        collection
                            .isAutoOrganized,

                    trackIDs:
                        collection.trackIDs,

                    createdAt:
                        collection.createdAt
                )


            context.insert(saved)
        }


        do { try context.save() }
        catch { context.rollback(); throw error }
    }


    // MARK: - DELETE

    func delete(
        id: UUID
    ) throws {

        guard let collection =
            find(id: id)
        else {
            return
        }


        context.delete(
            collection
        )


        try saveContext()
    }


    func deleteAll() throws {
        let descriptor = FetchDescriptor<SavedCollection>()

        let collections = try context.fetch(descriptor)

        for collection in collections {
            context.delete(collection)
        }

        try saveContext()
    }


    // MARK: - SAVE

    private func saveContext() throws {
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
}
