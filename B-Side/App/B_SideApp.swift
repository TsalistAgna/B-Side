//
//  B_SideApp.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import SwiftData

@main
struct BSideApp: App {

    var body: some Scene {

        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: SavedTrack.self
        )
    }
}
