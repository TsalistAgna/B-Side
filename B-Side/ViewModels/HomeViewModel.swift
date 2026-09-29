//
//  HomeViewModel.swift
//  B-Side
//

import Photos
import SwiftData
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published private(set) var processedLibraryTracks: [Track] = []
    @Published var customCollections: [CustomCollection] = []
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var isProcessingLibrary = false
    @Published var processedScreenshotCount = 0
    @Published var totalScreenshotCount = 0
    @Published var isPausedForTemperature = false
    @Published var collectionOrganizationError: String?
    @Published var organizingCollectionIDs: Set<UUID> = []

    private let photoService = PhotoLibraryService()
    private var persistenceService: TrackPersistenceService?
    private var collectionPersistenceService: CollectionPersistenceService?
    private var isFoundationModelBusy = false

    private let dailyFindingIDKey = "dailyFindingTrackID"
    private let dailyFindingDateKey = "dailyFindingDate"
    private let previousFindingIDKey = "previousFindingTrackID"

    init() {
        permissionStatus = photoService.currentPermission()
    }

    var latestTracks: [Track] {
        Array(tracks.sorted { $0.createdAt > $1.createdAt }.prefix(20))
    }

    var processedTracks: [Track] {
        processedLibraryTracks
    }

    var collections: [BSideCollection] {
        var grouped: [String: (name: String, tracks: [Track])] = [:]

        for track in processedLibraryTracks {
            guard let rawName = track.categoryName else {
                continue
            }

            let name = CategoryNameNormalizer.normalizedDisplayName(rawName)
            let key = CategoryNameNormalizer.comparisonKey(for: name)

            if grouped[key] == nil {
                grouped[key] = (name, [])
            }
            grouped[key]?.tracks.append(track)
        }

        return grouped.values
            .map { BSideCollection(name: $0.name, tracks: $0.tracks) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var todaysFinding: Track? {
        let availableTracks = tracks.filter(\.isProcessed)
        guard !availableTracks.isEmpty else {
            return nil
        }

        let defaults = UserDefaults.standard
        let calendar = Calendar.current

        if let date = defaults.object(forKey: dailyFindingDateKey) as? Date,
           calendar.isDateInToday(date),
           let savedID = defaults.string(forKey: dailyFindingIDKey),
           let savedTrack = availableTracks.first(where: { $0.id == savedID }) {
            return savedTrack
        }

        let previousID = defaults.string(forKey: previousFindingIDKey)
        let candidates = availableTracks.filter { $0.id != previousID }
        guard let finding = (candidates.isEmpty ? availableTracks : candidates).randomElement() else {
            return nil
        }

        if let oldID = defaults.string(forKey: dailyFindingIDKey) {
            defaults.set(oldID, forKey: previousFindingIDKey)
        }
        defaults.set(finding.id, forKey: dailyFindingIDKey)
        defaults.set(Date(), forKey: dailyFindingDateKey)
        return finding
    }

    func configurePersistence(context: ModelContext) {
        guard persistenceService == nil else {
            return
        }

        CategoryMigrationService(context: context)
            .migrateLegacyCategoryNames()
        persistenceService = TrackPersistenceService(context: context)
        collectionPersistenceService = CollectionPersistenceService(context: context)
        refreshPersistedLibrary()
        customCollections = collectionPersistenceService?.fetchAll() ?? []
    }

    func prepare() async {
        permissionStatus = photoService.currentPermission()

        switch permissionStatus {
        case .notDetermined:
            await requestPermission()
        case .authorized, .limited:
            await loadLatestTracks()
            startLibraryProcessing()
        default:
            break
        }
    }

    func requestPermission() async {
        permissionStatus = await photoService.requestPermission()

        if permissionStatus == .authorized || permissionStatus == .limited {
            await loadLatestTracks()
            startLibraryProcessing()
        }
    }

    func loadLatestTracks() async {
        guard let persistenceService else {
            return
        }

        isLoading = true
        var latest = await photoService.fetchLatestScreenshots(limit: 20)
        let savedByID = Dictionary(
            uniqueKeysWithValues: persistenceService.fetchAll().map { ($0.assetID, $0) }
        )

        latest.removeAll { savedByID[$0.id]?.isExcluded == true }

        for index in latest.indices {
            guard let saved = savedByID[latest[index].id], !saved.isExcluded else {
                continue
            }
            apply(saved, to: &latest[index])
        }

        tracks = latest
        isLoading = false
    }

    func tracks(inCategory categoryName: String) -> [Track] {
        let key = CategoryNameNormalizer.comparisonKey(for: categoryName)
        return processedLibraryTracks
            .filter {
                guard let name = $0.categoryName else { return false }
                return CategoryNameNormalizer.comparisonKey(for: name) == key
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func tracks(in collection: CustomCollection) -> [Track] {
        let ids = Set(collection.trackIDs)
        return processedLibraryTracks
            .filter { ids.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func image(for assetID: String) async -> UIImage? {
        await photoService.loadImage(assetID: assetID)
    }

    func updateTrack(_ updatedTrack: Track) {
        var normalizedTrack = updatedTrack
        normalizedTrack.categoryName = updatedTrack.categoryName.map(
            CategoryNameNormalizer.normalizedDisplayName
        )

        replaceTrack(normalizedTrack, in: &tracks)
        replaceTrack(normalizedTrack, in: &processedLibraryTracks)
        persistenceService?.save(track: normalizedTrack)
    }

    func deleteTrackFromBSide(id: String) {
        tracks.removeAll { $0.id == id }
        processedLibraryTracks.removeAll { $0.id == id }
        persistenceService?.exclude(assetID: id)

        for index in customCollections.indices where customCollections[index].trackIDs.contains(id) {
            customCollections[index].trackIDs.removeAll { $0 == id }
            collectionPersistenceService?.save(customCollections[index])
        }
    }

    @discardableResult
    func createCollection(
        name: String,
        vinylStyle: VinylStyle,
        autoOrganize: Bool
    ) -> CustomCollection {
        let collection = CustomCollection(
            name: name,
            vinylStyle: vinylStyle,
            isAutoOrganized: autoOrganize
        )
        customCollections.append(collection)
        collectionPersistenceService?.save(collection)
        return collection
    }

    func updateCollection(_ collection: CustomCollection) {
        guard let index = customCollections.firstIndex(where: { $0.id == collection.id }) else {
            return
        }
        customCollections[index] = collection
        collectionPersistenceService?.save(collection)
    }

    func deleteCollection(id: UUID) {
        customCollections.removeAll { $0.id == id }
        collectionPersistenceService?.delete(id: id)
    }

    func addTrack(trackID: String, to collectionID: UUID) {
        guard let index = customCollections.firstIndex(where: { $0.id == collectionID }),
              !customCollections[index].trackIDs.contains(trackID)
        else {
            return
        }
        customCollections[index].trackIDs.append(trackID)
        collectionPersistenceService?.save(customCollections[index])
    }

    func removeTrack(trackID: String, from collectionID: UUID) {
        guard let index = customCollections.firstIndex(where: { $0.id == collectionID }) else {
            return
        }
        customCollections[index].trackIDs.removeAll { $0 == trackID }
        collectionPersistenceService?.save(customCollections[index])
    }

    func autoOrganize(collectionID: UUID) async {
        guard #available(iOS 27.0, *),
              let index = customCollections.firstIndex(where: { $0.id == collectionID })
        else {
            return
        }

        organizingCollectionIDs.insert(collectionID)
        collectionOrganizationError = nil
        defer { organizingCollectionIDs.remove(collectionID) }

        await acquireFoundationModel()
        defer { releaseFoundationModel() }

        do {
            let matchingIDs = try await CollectionOrganizer().organize(
                tracks: processedLibraryTracks,
                collectionName: customCollections[index].name
            )
            customCollections[index].trackIDs = matchingIDs
            collectionPersistenceService?.save(customCollections[index])
        } catch {
            collectionOrganizationError = error.localizedDescription
        }
    }

    private func startLibraryProcessing() {
        guard !isProcessingLibrary else {
            return
        }
        Task { await processEntireScreenshotLibrary() }
    }

    private func processEntireScreenshotLibrary() async {
        guard #available(iOS 27.0, *), let persistenceService else {
            return
        }

        let screenshots = await photoService.fetchAllScreenshotInfos()
        let savedIDs = persistenceService.allAssetIDs()
        let unprocessed = screenshots.filter { !savedIDs.contains($0.id) }

        totalScreenshotCount = screenshots.count
        processedScreenshotCount = screenshots.count - unprocessed.count
        guard !unprocessed.isEmpty else {
            return
        }

        isProcessingLibrary = true
        isAnalyzing = true
        defer {
            isProcessingLibrary = false
            isAnalyzing = false
        }

        let analyzer = ScreenshotAnalyzer()
        var existingCategories = persistenceService.allCategoryNames()

        for (index, screenshot) in unprocessed.enumerated() {
            guard !Task.isCancelled else { break }
            await waitIfDeviceIsHot()

            guard let image = await photoService.loadImage(assetID: screenshot.id) else {
                continue
            }

            do {
                await acquireFoundationModel()
                let analysis: ScreenshotAnalysis
                do {
                    analysis = try await analyzer.analyze(
                        image: image,
                        existingCategories: existingCategories
                    )
                } catch {
                    releaseFoundationModel()
                    throw error
                }
                releaseFoundationModel()

                persistenceService.saveAnalysis(
                    assetID: screenshot.id,
                    createdAt: screenshot.createdAt,
                    analysis: analysis
                )
                processedScreenshotCount += 1
                refreshPersistedLibrary()
                existingCategories = persistenceService.allCategoryNames()
            } catch {
                print("❌ Screenshot analysis failed:", error)
            }

            if (index + 1).isMultiple(of: 3) {
                try? await Task.sleep(for: .seconds(2))
            }
        }

        await loadLatestTracks()
    }

    private func refreshPersistedLibrary() {
        processedLibraryTracks = persistenceService?.fetchAllMetadata() ?? []
    }

    private func apply(_ saved: SavedTrack, to track: inout Track) {
        track.title = saved.title
        track.rediscoveryDescription = saved.rediscoveryDescription
        track.detailDescription = saved.detailDescription
        track.tags = saved.tags
        track.categoryName = CategoryNameNormalizer
            .normalizedDisplayName(saved.categoryName)
    }

    private func replaceTrack(_ track: Track, in collection: inout [Track]) {
        guard let index = collection.firstIndex(where: { $0.id == track.id }) else {
            return
        }
        collection[index] = track
    }

    private func acquireFoundationModel() async {
        while isFoundationModelBusy {
            try? await Task.sleep(for: .milliseconds(150))
        }
        isFoundationModelBusy = true
    }

    private func releaseFoundationModel() {
        isFoundationModelBusy = false
    }

    private func waitIfDeviceIsHot() async {
        while true {
            switch ProcessInfo.processInfo.thermalState {
            case .nominal:
                isPausedForTemperature = false
                return
            case .fair:
                isPausedForTemperature = false
                try? await Task.sleep(for: .seconds(3))
                return
            case .serious, .critical:
                isPausedForTemperature = true
                try? await Task.sleep(for: .seconds(15))
            @unknown default:
                return
            }
        }
    }
}
