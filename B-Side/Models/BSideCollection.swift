//
//  BSideCollection.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import Foundation

struct BSideCollection: Identifiable {

    let name: String

    let tracks: [Track]


    var id: String {
        CategoryNameNormalizer.comparisonKey(for: name)
    }


    var trackCount: Int {
        tracks.count
    }
}
