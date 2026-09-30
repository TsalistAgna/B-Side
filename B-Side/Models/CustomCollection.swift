//
//  CustomCollection.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import Foundation

struct CustomCollection: Identifiable, Equatable {

    let id: UUID

    var name: String

    var vinylStyle: VinylStyle

    var isAutoOrganized: Bool

    var trackIDs: [String]

    var createdAt: Date


    init(
        id: UUID = UUID(),
        name: String,
        vinylStyle: VinylStyle,
        isAutoOrganized: Bool,
        trackIDs: [String] = [],
        createdAt: Date = Date()
    ) {

        self.id = id

        self.name = name

        self.vinylStyle =
            vinylStyle

        self.isAutoOrganized =
            isAutoOrganized

        self.trackIDs =
            trackIDs

        self.createdAt =
            createdAt
    }
}
