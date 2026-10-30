//
//  ScreenshotAssetInfo.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 28/09/26.
//

import Foundation

nonisolated struct ScreenshotAssetInfo: Identifiable, Sendable {

    let id: String

    let createdAt: Date
    var hasCreationDate = true
}
