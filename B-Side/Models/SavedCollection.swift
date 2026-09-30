//
//  SavedCollection.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 29/09/26.
//

import Foundation
import SwiftData

@Model
final class SavedCollection {

    @Attribute(.unique)
    var id: UUID

    var name: String

    var vinylStyleName: String

    var isAutoOrganized: Bool

    var trackIDsData: Data

    var createdAt: Date


    init(
        id: UUID = UUID(),
        name: String,
        vinylStyleName: String,
        isAutoOrganized: Bool,
        trackIDs: [String] = [],
        createdAt: Date = Date()
    ) {

        self.id = id

        self.name = name

        self.vinylStyleName =
            vinylStyleName

        self.isAutoOrganized =
            isAutoOrganized

        self.trackIDsData =
            (
                try? JSONEncoder()
                    .encode(trackIDs)
            ) ?? Data()

        self.createdAt =
            createdAt
    }


    var trackIDs: [String] {

        get {

            (
                try? JSONDecoder()
                    .decode(
                        [String].self,
                        from:
                            trackIDsData
                    )
            ) ?? []
        }

        set {

            trackIDsData =
                (
                    try? JSONEncoder()
                        .encode(newValue)
                ) ?? Data()
        }
    }
}
