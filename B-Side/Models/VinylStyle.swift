//
//  VinylStyle.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import SwiftUI

enum VinylStyle: String, CaseIterable, Identifiable, Codable {

    case pink
    case red
    case yellow
    case mint

    var id: String {
        rawValue
    }

    var color: Color {

        switch self {

        case .pink:
            return Color(hex: "FEC4EB")

        case .red:
            return Color(hex: "FF6868")

        case .yellow:
            return Color(hex: "FFEFA8")

        case .mint:
            return Color(hex: "8CEFE6")
        }
    }
}
