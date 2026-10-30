//
//  AppPreferences.swift
//  B-Side
//

import Foundation

enum AppPreferences {
    static let processNewScreenshotsKey = "processNewScreenshots"
    static let autoOrganizeNewTracksKey = "autoOrganizeNewTracks"
    static let onDeviceAnalysisKey = "onDeviceAnalysis"

    static var shouldProcessNewScreenshots: Bool {
        value(forKey: processNewScreenshotsKey, defaultValue: true)
    }

    static var shouldAutoOrganizeNewTracks: Bool {
        value(forKey: autoOrganizeNewTracksKey, defaultValue: true)
    }

    static var shouldUseOnDeviceAnalysis: Bool {
        value(forKey: onDeviceAnalysisKey, defaultValue: true)
    }

    private static func value(
        forKey key: String,
        defaultValue: Bool
    ) -> Bool {
        let defaults = UserDefaults.standard

        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return defaults.bool(forKey: key)
    }
}
