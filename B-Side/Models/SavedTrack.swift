//
//  SavedTrack.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 18/09/26.
//

import Foundation
import SwiftData

@Model
final class SavedTrack {

    @Attribute(.unique)
    var assetID: String

    var createdAt: Date

    var title: String

    var rediscoveryDescription: String

    var detailDescription: String

    var tagsText: String

    var categoryName: String

    var isExcluded: Bool


    init(
        assetID: String,
        createdAt: Date,
        title: String,
        rediscoveryDescription: String,
        detailDescription: String,
        tags: [String],
        categoryName: String,
        isExcluded: Bool = false
    ) {

        self.assetID = assetID

        self.createdAt = createdAt

        self.title = title

        self.rediscoveryDescription =
            rediscoveryDescription

        self.detailDescription =
            detailDescription

        self.tagsText =
            tags.joined(
                separator: "|||"
            )

        self.categoryName =
            categoryName

        self.isExcluded =
            isExcluded
    }


    var tags: [String] {

        guard !tagsText.isEmpty else {
            return []
        }

        return tagsText.components(
            separatedBy: "|||"
        )
    }
}
