//
//  BSideCategoryStorage.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 18/09/26.
//

extension BSideCategory {

    var storageName: String {

        switch self {

        case .thingsToBuy:
            return "thingsToBuy"

        case .placesToVisit:
            return "placesToVisit"

        case .designInspiration:
            return "designInspiration"

        case .food:
            return "food"

        case .events:
            return "events"

        case .conversations:
            return "conversations"

        case .workStudy:
            return "workStudy"

        case .travel:
            return "travel"

        case .memesFun:
            return "memesFun"

        case .readLater:
            return "readLater"
        }
    }


    init?(storageName: String) {

        switch storageName {

        case "thingsToBuy":
            self = .thingsToBuy

        case "placesToVisit":
            self = .placesToVisit

        case "designInspiration":
            self = .designInspiration

        case "food":
            self = .food

        case "events":
            self = .events

        case "conversations":
            self = .conversations

        case "workStudy":
            self = .workStudy

        case "travel":
            self = .travel

        case "memesFun":
            self = .memesFun

        case "readLater":
            self = .readLater

        default:
            return nil
        }
    }
}
