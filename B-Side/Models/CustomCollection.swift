//
//  CustomCollection.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import Foundation

struct CustomCollection: Identifiable {

    let id: UUID

    var name: String

    var vinylStyle: VinylStyle

    var isAutoOrganized: Bool

    var trackIDs: [String]


    init(
        id: UUID = UUID(),
        name: String,
        vinylStyle: VinylStyle,
        isAutoOrganized: Bool,
        trackIDs: [String] = []
    ) {

        self.id = id
        self.name = name
        self.vinylStyle = vinylStyle
        self.isAutoOrganized = isAutoOrganized
        self.trackIDs = trackIDs
    }
}
