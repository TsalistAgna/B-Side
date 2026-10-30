//
//  CategoryStyle.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 29/09/26.
//

import Foundation

struct CategoryStyle {

    static func vinylStyle(
        for categoryName: String
    ) -> VinylStyle {

        let normalizedName = CategoryNameNormalizer
            .comparisonKey(for: categoryName)

        let hash = normalizedName.unicodeScalars.reduce(5381) {
            (($0 << 5) &+ $0) &+ Int($1.value)
        }

        let styles = VinylStyle.allCases
        let index = abs(hash % styles.count)

        return styles[index]
    }
}
