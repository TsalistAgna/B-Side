//
//  VinylStyle.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import Foundation

enum VinylStyle: String, CaseIterable, Identifiable, Codable {

    case pink
    case orange = "red"
    case yellow
    case green = "mint"
    case blue
    case black

    var id: String {
        rawValue
    }

    var imageName: String {
        switch self {
        case .pink:
            return "vinyl_pink"
        case .orange:
            return "vinyl_orange"
        case .yellow:
            return "vinyl_yellow"
        case .green:
            return "vinyl_green"
        case .blue:
            return "vinyl_blue"
        case .black:
            return "vinyl_black"
        }
    }

    var displayName: String {
        switch self {
        case .pink:
            return "Pink"
        case .orange:
            return "Orange"
        case .yellow:
            return "Yellow"
        case .green:
            return "Green"
        case .blue:
            return "Blue"
        case .black:
            return "Black"
        }
    }
}
