//
//  BSideCollection.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import Foundation

struct BSideCollection: Identifiable {

    let category: BSideCategory
    let tracks: [Track]

    var id: String {
        category.title
    }

    var trackCount: Int {
        tracks.count
    }
}
