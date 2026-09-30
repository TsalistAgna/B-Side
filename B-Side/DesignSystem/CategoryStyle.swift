//
//  CategoryStyle.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 29/09/26.
//

import SwiftUI

struct CategoryStyle {

    static func color(
        for categoryName: String
    ) -> Color {

        let colors: [Color] = [
            Color(hex: "FEC4EB"),
            Color(hex: "FF6868"),
            Color(hex: "FFEFA8"),
            Color(hex: "8CEFE6"),
            Color(hex: "A0BCF8"),
            Color(hex: "749DF5"),
            Color(hex: "D89CC4"),
            Color(hex: "FEB7E7")
        ]

        let normalizedName = CategoryNameNormalizer
            .comparisonKey(for: categoryName)

        let hash = normalizedName.unicodeScalars.reduce(5381) {
            (($0 << 5) &+ $0) &+ Int($1.value)
        }

        let index =
            abs(hash % colors.count)

        return colors[index]
    }
}
