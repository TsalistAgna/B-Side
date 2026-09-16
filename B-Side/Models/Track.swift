//
//  Track.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import UIKit

struct Track: Identifiable {

    let id: String

    let image: UIImage

    let createdAt: Date

    var title: String?

    var rediscoveryDescription: String?
    var detailDescription: String?
    
    var tags: [String]

    var category: BSideCategory?


    var isProcessed: Bool {
        title != nil &&
        rediscoveryDescription != nil &&
        detailDescription != nil &&
        category != nil
    }
}
