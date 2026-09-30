//
//  Track.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import UIKit

struct Track: Identifiable {

    let id: String

    var image: UIImage?

    let createdAt: Date

    var title: String?

    var rediscoveryDescription: String?
    var detailDescription: String?
    
    var tags: [String]

    var categoryName: String?


    var isProcessed: Bool {
            title != nil &&
            rediscoveryDescription != nil &&
            detailDescription != nil &&
            categoryName != nil
    }

    init(
        id: String,
        image: UIImage? = nil,
        createdAt: Date,
        title: String? = nil,
        rediscoveryDescription: String? = nil,
        detailDescription: String? = nil,
        tags: [String] = [],
        categoryName: String? = nil
    ) {
        self.id = id
        self.image = image
        self.createdAt = createdAt
        self.title = title
        self.rediscoveryDescription = rediscoveryDescription
        self.detailDescription = detailDescription
        self.tags = tags
        self.categoryName = categoryName
    }
}
