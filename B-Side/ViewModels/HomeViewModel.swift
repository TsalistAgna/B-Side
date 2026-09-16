//
//  HomeView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import Photos
import Combine


@MainActor
final class HomeViewModel: ObservableObject {

    @Published var tracks: [Track] = []

    @Published var permissionStatus:
        PHAuthorizationStatus = .notDetermined

    @Published var isLoading = false

    @Published var isAnalyzing = false


    private let dailyFindingIDKey =
        "dailyFindingTrackID"

    private let dailyFindingDateKey =
        "dailyFindingDate"
    
    private let previousFindingIDKey =
        "previousFindingTrackID"
    
    private let photoService =
        PhotoLibraryService()


    init() {

        permissionStatus =
            photoService.currentPermission()
    }


    // MARK: - Latest Tracks

    var latestTracks: [Track] {

        Array(
            tracks
                .sorted {
                    $0.createdAt > $1.createdAt
                }
                .prefix(20)
        )
    }


    // MARK: - Processed Tracks

    var processedTracks: [Track] {

        tracks.filter {
            $0.isProcessed
        }
    }


    // MARK: - B-Side Collections

    var collections: [BSideCollection] {

        BSideCategory.allCases.compactMap { category in

            let matchingTracks =
                processedTracks.filter {
                    $0.category == category
                }


            guard !matchingTracks.isEmpty else {
                return nil
            }


            return BSideCollection(
                category: category,
                tracks: matchingTracks
            )
        }
    }


    // MARK: - Today's Finding

    var todaysFinding: Track? {

        guard !processedTracks.isEmpty else {
            return nil
        }

        let defaults = UserDefaults.standard
        let calendar = Calendar.current


        // MARK: Existing Finding Today

        if let savedDate =
            defaults.object(
                forKey: dailyFindingDateKey
            ) as? Date,

           calendar.isDateInToday(savedDate),

           let savedID =
            defaults.string(
                forKey: dailyFindingIDKey
           ),

           let savedTrack =
            processedTracks.first(
                where: {
                    $0.id == savedID
                }
            ) {

            return savedTrack
        }


        // MARK: Pick New Finding

        let previousID =
            defaults.string(
                forKey: previousFindingIDKey
            )


        var candidates =
            processedTracks.filter {
                $0.id != previousID
            }


        // If there is only one Track,
        // allow it to be reused.
        if candidates.isEmpty {
            candidates = processedTracks
        }


        guard let randomTrack =
            candidates.randomElement()
        else {
            return nil
        }


        // Move today's old finding into previous.
        if let oldFindingID =
            defaults.string(
                forKey: dailyFindingIDKey
            ) {

            defaults.set(
                oldFindingID,
                forKey: previousFindingIDKey
            )
        }


        defaults.set(
            randomTrack.id,
            forKey: dailyFindingIDKey
        )

        defaults.set(
            Date(),
            forKey: dailyFindingDateKey
        )


        return randomTrack
    }


    // MARK: - Prepare App

    func prepare() async {

        print("Prepare started")

        permissionStatus =
            photoService.currentPermission()

        print("Permission status:", permissionStatus.rawValue)

        switch permissionStatus {

        case .notDetermined:
            print("Asking permission")
            await requestPermission()

        case .authorized, .limited:
            print("Permission already granted")
            await loadScreenshots()

        default:
            print("Photo access unavailable")
        }
    }


    // MARK: - Permission

    func requestPermission() async {

        print("Requesting photo permission...")

        let status =
            await photoService.requestPermission()

        permissionStatus = status

        print("Permission result:", status.rawValue)

        if status == .authorized ||
            status == .limited {

            print("Loading screenshots")

            await loadScreenshots()
        }
    }


    // MARK: - Load Screenshots

    func loadScreenshots() async {

        print("Start loading screenshots")

        isLoading = true

        let loadedTracks =
            await photoService.fetchLatestScreenshots(
                limit: 200
            )

        tracks = loadedTracks.filter {
            !excludedTrackIDs.contains($0.id)
        }

        print("Screenshots found:", tracks.count)

        isLoading = false

        print("Start AI analysis")

        await analyzeUnprocessedTracks()
    }

    // MARK: - Tracks By Collection

    func tracks(
        in category: BSideCategory
    ) -> [Track] {

        tracks
            .filter {
                $0.category == category
            }
            .sorted {
                $0.createdAt > $1.createdAt
            }
    }


    // MARK: - Update Track

    func updateTrack(
        _ updatedTrack: Track
    ) {

        guard let index = tracks.firstIndex(
            where: {
                $0.id == updatedTrack.id
            }
        ) else {
            return
        }

        tracks[index] = updatedTrack
    }


    // MARK: - Delete From B-Side

    func deleteTrackFromBSide(
        id: String
    ) {

        tracks.removeAll {
            $0.id == id
        }

        saveExcludedTrackID(id)
    }

    // MARK: - AI Analysis

    private func analyzeUnprocessedTracks() async {

        guard #available(iOS 27.0, *) else {
            return
        }


        isAnalyzing = true


        let analyzer =
            ScreenshotAnalyzer()


        for index in tracks.indices {

            // Don't analyze something twice.
            guard !tracks[index].isProcessed else {
                continue
            }


            do {

                let result =
                    try await analyzer.analyze(
                        image: tracks[index].image
                    )


                tracks[index].title =
                    result.title

                tracks[index].rediscoveryDescription =
                    result.rediscoveryDescription
                
                tracks[index].detailDescription =
                    result.detailDescription

                tracks[index].tags =
                    result.tags

                tracks[index].category =
                    result.category

            } catch {

                print(
                    "Failed to analyze screenshot:",
                    error
                )
            }
        }


        isAnalyzing = false
    }
    
    private let excludedTrackIDsKey =
        "excludedBSideTrackIDs"


    private func saveExcludedTrackID(
        _ id: String
    ) {

        var excludedIDs = Set(
            UserDefaults.standard.stringArray(
                forKey: excludedTrackIDsKey
            ) ?? []
        )

        excludedIDs.insert(id)

        UserDefaults.standard.set(
            Array(excludedIDs),
            forKey: excludedTrackIDsKey
        )
    }


    private var excludedTrackIDs: Set<String> {

        Set(
            UserDefaults.standard.stringArray(
                forKey: excludedTrackIDsKey
            ) ?? []
        )
    }
}
