//
//  BSideCategoryUI.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

extension BSideCategory {

    var title: String {

        switch self {

        case .thingsToBuy:
            return "Things to Buy"

        case .placesToVisit:
            return "Places to Visit"

        case .designInspiration:
            return "Design Inspiration"

        case .food:
            return "Food"

        case .events:
            return "Events"

        case .conversations:
            return "Conversations"

        case .workStudy:
            return "Work & Study"

        case .travel:
            return "Travel"

        case .memesFun:
            return "Memes & Fun"

        case .readLater:
            return "Read Later"
        }
    }


    var accentColor: Color {

        switch self {

        case .thingsToBuy:
            return Color(hex: "FEC4EB")

        case .placesToVisit:
            return Color(hex: "FEB7E7")

        case .designInspiration:
            return Color(hex: "A0BCF8")

        case .food:
            return Color(hex: "FF6868")

        case .events:
            return Color(hex: "FFEFA8")

        case .conversations:
            return Color(hex: "CADAFB")

        case .workStudy:
            return Color(hex: "749DF5")

        case .travel:
            return Color(hex: "F7A8DA")

        case .memesFun:
            return Color(hex: "8CEFE6")

        case .readLater:
            return Color(hex: "D89CC4")
        }
    }
}
