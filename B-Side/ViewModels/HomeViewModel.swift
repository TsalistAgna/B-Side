//
//  HomeViewModel.swift
//  B-Side
//

import Photos
import PhotosUI
import SwiftData
import SwiftUI
import Combine
import OSLog

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published private(set) var processedLibraryTracks: [Track] = []
    @Published var customCollections: [CustomCollection] = []
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published private(set) var processingState: ScreenshotProcessingState = .idle
    @Published var trackSaveError: String?
    var isAnalyzing: Bool { processingState.active }
    private let logger = Logger(subsystem: "Side-B", category: "Processing")
    @Published var collectionOrganizationError: String?
    @Published var organizingCollectionIDs: Set<UUID> = []

    private let photoService = PhotoLibraryService()
    private var persistenceService: TrackPersistenceService?
    private var collectionPersistenceService: CollectionPersistenceService?
    private var isFoundationModelBusy = false
    private var libraryProcessingTask: Task<Void, Never>?

    private let dailyFindingIDKey = "dailyFindingTrackID"
    private let dailyFindingDateKey = "dailyFindingDate"
    private let previousFindingIDKey = "previousFindingTrackID"

    var availabilityCheck: () -> AIUnavailableReason? = AIUnavailableReason.current
    var screenshotSource: (() async -> [ScreenshotAssetInfo])?
    var analysisOperation: ((String) async throws -> ScreenshotAnalysis)?

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

            if key == CategoryNameNormalizer.comparisonKey(for: "Uncategorized") {
                continue
            }

            if grouped[key] == nil {
                grouped[key] = (name, [])
            } else if let currentName = grouped[key]?.name {
                grouped[key]?.name = CategoryNameNormalizer
                    .preferredDisplayName(currentName, name)
            }
            grouped[key]?.tracks.append(track)
        }

        return grouped.values
            .map { BSideCollection(name: $0.name, tracks: $0.tracks) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var todaysFinding: Track? {
        let availableTracks = tracks
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
        tracks = processedLibraryTracks
        customCollections = collectionPersistenceService?.fetchAll() ?? []
    }

    func prepare() async {
        permissionStatus = photoService.currentPermission()

        switch permissionStatus {
        case .notDetermined:
            break
        case .authorized, .limited:
            await loadLatestTracks()
            await refreshScopeEstimate()
        default:
            break
        }
    }

    var photosAccess: PhotosAccessState { PhotosAccessState(permissionStatus) }
    var authorizationRequest: (() async -> PHAuthorizationStatus)?

    func requestPermission() async {
        guard photosAccess == .notDetermined else { return }
        if let authorizationRequest { permissionStatus = await authorizationRequest() }
        else { permissionStatus = await photoService.requestPermission() }

        if permissionStatus == .authorized || permissionStatus == .limited {
            await loadLatestTracks()
            await refreshScopeEstimate()
        }
    }

    func refreshPhotoPermissionStatus() {
        permissionStatus = photoService.currentPermission()
        if !photosAccess.canRead {
            stopProcessing()
            scopeItems = []
            tracks = processedLibraryTracks
        }
    }

    func refreshAccessiblePhotos() async {
        let previous = permissionStatus
        refreshPhotoPermissionStatus()
        guard photosAccess.canRead else { return }
        if previous != permissionStatus || AppPreferences.shouldProcessNewScreenshots {
            await loadLatestTracks()
        }
        await refreshScopeEstimate()
    }

    func managePhotoAccess() {
        guard photosAccess == .limited,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        var presenter = root
        while let next = presenter.presentedViewController { presenter = next }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter) { [weak self] _ in
            Task { @MainActor in await self?.refreshAccessiblePhotos() }
        }
    }

    func refreshProcessingForPreferences() {
        guard processingPreferencesEnabled else {
            stopProcessing()
            return
        }

        // Preference changes never authorize a new library-wide job.
    }

    func clearAllBSideData() {
        libraryProcessingTask?.cancel()
        // Keep the task registered until cancellation unwinds; prevent a second run.

        do {
            try persistenceService?.deleteAll()
            try collectionPersistenceService?.deleteAll()
        } catch {
            trackSaveError = "Side-B couldn’t finish clearing its local data. Your original screenshots remain in Photos. Try again."
            refreshPersistedLibrary()
            customCollections = collectionPersistenceService?.fetchAll() ?? []
            return
        }

        tracks.removeAll()
        processedLibraryTracks.removeAll()
        customCollections.removeAll()
        organizingCollectionIDs.removeAll()
        processingState = .idle
        scopeItems = []
        lastJobs = []
        remainingInScope = 0

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: dailyFindingIDKey)
        defaults.removeObject(forKey: dailyFindingDateKey)
        defaults.removeObject(forKey: previousFindingIDKey)
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

        tracks = latest.isEmpty && !processedLibraryTracks.isEmpty ? processedLibraryTracks : latest
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
            canonicalCategoryName
        )

        trackSaveError = nil
        do { try persistenceService?.save(track: normalizedTrack) }
        catch { trackSaveError = ProcessingFailure.save.message; return }
        replaceTrack(normalizedTrack, in: &tracks)

        var metadataTrack = normalizedTrack
        metadataTrack.image = nil
        replaceTrack(metadataTrack, in: &processedLibraryTracks)
        refreshPersistedLibrary()
    }

    func deleteTrackFromBSide(id: String) {
        do { try persistenceService?.exclude(assetID: id) }
        catch { trackSaveError = "Side-B couldn’t remove this Track. Try again."; return }
        tracks.removeAll { $0.id == id }
        processedLibraryTracks.removeAll { $0.id == id }

        for index in customCollections.indices where customCollections[index].trackIDs.contains(id) {
            customCollections[index].trackIDs.removeAll { $0 == id }
            saveCollection(customCollections[index])
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
        saveCollection(collection)
        return collection
    }

    func updateCollection(_ collection: CustomCollection) {
        guard let index = customCollections.firstIndex(where: { $0.id == collection.id }) else {
            return
        }
        customCollections[index] = collection
        saveCollection(collection)
    }

    func deleteCollection(id: UUID) {
        do { try collectionPersistenceService?.delete(id: id) }
        catch { trackSaveError = "Side-B couldn’t delete this collection. Try again."; return }
        customCollections.removeAll { $0.id == id }
    }

    func addTrack(trackID: String, to collectionID: UUID) {
        guard let index = customCollections.firstIndex(where: { $0.id == collectionID }),
              !customCollections[index].trackIDs.contains(trackID)
        else {
            return
        }
        customCollections[index].trackIDs.append(trackID)
        saveCollection(customCollections[index])
    }

    func removeTrack(trackID: String, from collectionID: UUID) {
        guard let index = customCollections.firstIndex(where: { $0.id == collectionID }) else {
            return
        }
        customCollections[index].trackIDs.removeAll { $0 == trackID }
        saveCollection(customCollections[index])
    }

    func updateTracks(for collectionID: UUID, trackIDs: [String]) {
        guard let index = customCollections.firstIndex(
            where: { $0.id == collectionID }
        ) else {
            return
        }

        customCollections[index].trackIDs = Array(Set(trackIDs))
        saveCollection(customCollections[index])
    }

    func updateTracks(inCategory categoryName: String, trackIDs: [String]) {
        let categoryKey = CategoryNameNormalizer.comparisonKey(for: categoryName)
        let selectedIDs = Set(trackIDs)

        for index in processedLibraryTracks.indices {
            let currentKey = processedLibraryTracks[index].categoryName.map {
                CategoryNameNormalizer.comparisonKey(for: $0)
            }
            let wasInCollection = currentKey == categoryKey
            let isSelected = selectedIDs.contains(processedLibraryTracks[index].id)

            guard wasInCollection || isSelected else {
                continue
            }

            let newCategory = isSelected ? categoryName : "Uncategorized"
            guard processedLibraryTracks[index].categoryName != newCategory else {
                continue
            }

            processedLibraryTracks[index].categoryName = newCategory
            do { try persistenceService?.save(track: processedLibraryTracks[index]) }
            catch { trackSaveError = ProcessingFailure.save.message; refreshPersistedLibrary(); return }
        }

        synchronizeLatestTrackCategories()
    }

    func renameAutomaticCollection(from oldName: String, to newName: String) {
        let oldKey = CategoryNameNormalizer.comparisonKey(for: oldName)
        let canonicalName = canonicalCategoryName(newName)

        for index in processedLibraryTracks.indices {
            guard let currentName = processedLibraryTracks[index].categoryName,
                  CategoryNameNormalizer.comparisonKey(for: currentName) == oldKey
            else {
                continue
            }

            processedLibraryTracks[index].categoryName = canonicalName
            do { try persistenceService?.save(track: processedLibraryTracks[index]) }
            catch { trackSaveError = ProcessingFailure.save.message; refreshPersistedLibrary(); return }
        }

        synchronizeLatestTrackCategories()
    }

    func deleteAutomaticCollection(named categoryName: String) {
        updateTracks(inCategory: categoryName, trackIDs: [])
    }

    func autoOrganize(collectionID: UUID) async {
        guard #available(iOS 27.0, *),
              let collection = customCollections.first(where: { $0.id == collectionID })
        else {
            return
        }

        guard !organizingCollectionIDs.contains(collectionID) else { return }
        if let reason = availabilityCheck() {
            collectionOrganizationError = reason.message
            return
        }
        organizingCollectionIDs.insert(collectionID)
        collectionOrganizationError = nil
        defer { organizingCollectionIDs.remove(collectionID) }

        do {
            try await acquireFoundationModel()
            defer { releaseFoundationModel() }
            try Task.checkCancellation()
            let matchingIDs = try await CollectionOrganizer().organize(
                tracks: processedLibraryTracks,
                collectionName: collection.name
            )
            guard let resultIndex = customCollections.firstIndex(
                where: { $0.id == collectionID }
            ) else {
                return
            }
            try Task.checkCancellation()
            customCollections[resultIndex].trackIDs = Array(Set(customCollections[resultIndex].trackIDs).union(matchingIDs))
            do { try collectionPersistenceService?.save(customCollections[resultIndex]) }
            catch {
                customCollections = collectionPersistenceService?.fetchAll() ?? []
                collectionOrganizationError = "Side-B couldn’t save this collection. Try again."
            }
        } catch is CancellationError {
            return
        } catch {
            logger.error("Collection organization failed")
            collectionOrganizationError = "Side-B couldn’t update this collection. Your screenshots are safe. Try again or add Tracks manually."
        }
    }

    func pauseProcessing() {
        guard case .processing(let p) = processingState else { return }
        processingState = .pausing(p)
    }

    func resumeProcessing() {
        guard case .paused(let p) = processingState else { return }
        processingState = .processing(p)
    }

    func stopProcessing() {
        guard processingState.active else { return }
        processingState = .cancelling(processingState.progress)
        libraryProcessingTask?.cancel()
    }

    @Published private(set) var scopeItems: [ScreenshotAssetInfo] = []
    @Published private(set) var scopeLoading = false
    @Published private(set) var remainingInScope = 0
    private var lastJobs: [ScreenshotAssetInfo] = []
    var canRetryProcessing: Bool { !lastJobs.isEmpty && !processingState.active }

    func refreshScopeEstimate() async {
        guard !scopeLoading else { return }
        scopeLoading = true
        defer { scopeLoading = false }
        let items: [ScreenshotAssetInfo]
        if let screenshotSource { items = await screenshotSource() }
        else { items = await photoService.fetchAllScreenshotInfos() }
        let excluded = Set((persistenceService?.fetchAll() ?? []).filter {
            $0.isExcluded || $0.userEdited || $0.analysisStatus != .pending
        }.map(\.assetID))
        scopeItems = ProcessingQueue.select(items, scope: .allUnprocessed, excluded: excluded)
    }

    func selectedJobs(scope: ProcessingScope, limit: Int?) -> [ScreenshotAssetInfo] {
        ProcessingQueue.select(scopeItems, scope: scope, excluded: [], limit: limit)
    }

    func startProcessing(scope: ProcessingScope, limit: Int?) {
        guard !processingState.active, libraryProcessingTask == nil else { return }
        let all = selectedJobs(scope: scope, limit: nil)
        let selected = selectedJobs(scope: scope, limit: limit)
        guard !selected.isEmpty else { return }
        remainingInScope = all.count - selected.count
        lastJobs = selected
        logger.info("Confirmed processing scope: \(selected.count) jobs; inference concurrency: 1")
        startLibraryProcessing(jobs: selected)
    }

    func retryProcessing() {
        guard !lastJobs.isEmpty else { return }
        let unresolved = lastJobs.filter {
            guard let saved = persistenceService?.findTrack(assetID: $0.id) else { return true }
            return !saved.isExcluded && !saved.userEdited && (saved.analysisStatus == .pending || saved.analysisStatus == .failed)
        }
        guard !unresolved.isEmpty else { return }
        startLibraryProcessing(jobs: unresolved)
    }

    func retryTrack(id: String) {
        guard !processingState.active, libraryProcessingTask == nil,
              let saved = persistenceService?.findTrack(assetID: id), !saved.isExcluded,
              !saved.userEdited, saved.analysisStatus == .failed || saved.analysisStatus == .pending else { return }
        lastJobs = [ScreenshotAssetInfo(id: id, createdAt: saved.createdAt)]
        remainingInScope = 0
        startLibraryProcessing(jobs: lastJobs)
    }

    func organizeManually() {
        stopProcessing()
        do {
            for track in tracks { try persistenceService?.register(assetID: track.id, createdAt: track.createdAt) }
            refreshPersistedLibrary()
        } catch { trackSaveError = ProcessingFailure.save.message }
    }

    private func startLibraryProcessing(jobs: [ScreenshotAssetInfo]) {
        guard libraryProcessingTask == nil, !processingState.active,
                            permissionStatus == .authorized || permissionStatus == .limited else { return }
        guard AppPreferences.shouldUseOnDeviceAnalysis else {
            processingState = .unavailable(.analysisDisabled)
            return
        }
        processingState = .preparing
        libraryProcessingTask = Task {
            await processEntireScreenshotLibrary(jobs: jobs)
            libraryProcessingTask = nil
        }
    }

    private func processEntireScreenshotLibrary(jobs: [ScreenshotAssetInfo]) async {
        guard let persistenceService else { processingState = .idle; return }
        var progress = ProcessingProgress()
        do {
            let screenshots = jobs
            try Task.checkCancellation()
            // Index first: manual collection selection must not depend on AI success.
            for screenshot in screenshots {
                await Task.yield()
                try Task.checkCancellation()
                do { try persistenceService.register(assetID: screenshot.id, createdAt: screenshot.createdAt) }
                catch { throw ProcessingFailure.save }
            }
            refreshPersistedLibrary()
            let pending = screenshots.filter {
                guard let saved = persistenceService.findTrack(assetID: $0.id), !saved.isExcluded else { return false }
                return saved.analysisStatus == .pending || saved.analysisStatus == .failed
            }
            progress.total = pending.count
            if let reason = availabilityCheck() { processingState = .unavailable(reason); return }
            processingState = .processing(progress)
            var existingCategories = persistenceService.allCategoryNames()
            for screenshot in pending {
                try await waitForProcessingPermission(progress)
                try await acquireFoundationModel()
                do {
                    try await waitForProcessingPermission(progress)
                    if let reason = availabilityCheck() {
                        releaseFoundationModel()
                        processingState = .unavailable(reason)
                        return
                    }
                    guard let saved = persistenceService.findTrack(assetID: screenshot.id), !saved.isExcluded, !saved.userEdited, saved.analysisStatus != .completed else {
                        releaseFoundationModel()
                        progress.total -= 1
                        continue
                    }
                    var result: ScreenshotAnalysis
                    if let analysisOperation { result = try await analysisOperation(screenshot.id) }
                    else {
                        guard let image = await photoService.loadImage(assetID: screenshot.id, forAnalysis: true) else { throw ScreenshotAnalyzerError.invalidImage }
                        try Task.checkCancellation()
                        result = try await ScreenshotAnalyzer().analyze(image: image, existingCategories: existingCategories)
                    }
                    try Task.checkCancellation()
                    if !AppPreferences.shouldAutoOrganizeNewTracks { result.categoryName = "Uncategorized" }
                    do {
                        try persistenceService.saveAnalysis(assetID: screenshot.id, createdAt: screenshot.createdAt, analysis: result)
                    } catch { throw ProcessingFailure.save }
                    if persistenceService.findTrack(assetID: screenshot.id)?.analysisStatus == .completed {
                        progress.completed += 1
                        if !existingCategories.contains(result.categoryName) { existingCategories.append(result.categoryName) }
                    } else { progress.total -= 1 }
                    releaseFoundationModel()
                } catch {
                    releaseFoundationModel()
                    if Task.isCancelled || error is CancellationError { throw CancellationError() }
                    if let failure = error as? ProcessingFailure, failure == .save { throw failure }
                    logger.error("Screenshot analysis failed; item remains retryable")
                    do { try persistenceService.markFailed(screenshot.id) }
                    catch { throw ProcessingFailure.save }
                    progress.failed += 1
                }
                if let saved = persistenceService.findTrack(assetID: screenshot.id) {
                    var item = Track(id: screenshot.id, createdAt: screenshot.createdAt)
                    apply(saved, to: &item)
                    replaceTrack(item, in: &processedLibraryTracks)
                }
                if case .pausing = processingState { processingState = .pausing(progress) }
                else { processingState = .processing(progress) }
            }
            processingState = .completed(progress)
        } catch is CancellationError {
            processingState = .stopped(progress)
        } catch {
            logger.error("Screenshot run stopped before saving completed")
            processingState = .failed((error as? ProcessingFailure) ?? .analysis, progress)
        }
        refreshPersistedLibrary()
        for index in tracks.indices {
            if let saved = persistenceService.findTrack(assetID: tracks[index].id) {
                apply(saved, to: &tracks[index])
            }
        }
    }

    private func waitForProcessingPermission(_ progress: ProcessingProgress) async throws {
        try Task.checkCancellation()
        if case .pausing = processingState { processingState = .paused(progress) }
        while case .paused = processingState {
            try await Task.sleep(for: .milliseconds(150))
        }
        while ProcessInfo.processInfo.thermalState == .serious || ProcessInfo.processInfo.thermalState == .critical {
            if case .processing = processingState { processingState = .cooling(progress) }
            try await Task.sleep(for: .seconds(1))
            if case .pausing = processingState { processingState = .paused(progress) }
            while case .paused = processingState { try await Task.sleep(for: .milliseconds(150)) }
        }
        try Task.checkCancellation()
        if case .cooling = processingState { processingState = .processing(progress) }
    }

    private func saveCollection(_ collection: CustomCollection) {
        do { try collectionPersistenceService?.save(collection) }
        catch {
            trackSaveError = ProcessingFailure.save.message
            customCollections = collectionPersistenceService?.fetchAll() ?? []
        }
    }

    func analysisStatus(for id: String) -> TrackAnalysisStatus {
        persistenceService?.findTrack(assetID: id)?.analysisStatus ?? .pending
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

    private func synchronizeLatestTrackCategories() {
        let categoriesByID = Dictionary(
            uniqueKeysWithValues: processedLibraryTracks.map {
                ($0.id, $0.categoryName)
            }
        )

        for index in tracks.indices {
            if let categoryName = categoriesByID[tracks[index].id] {
                tracks[index].categoryName = categoryName
            }
        }
    }

    private func canonicalCategoryName(_ name: String) -> String {
        let normalized = CategoryNameNormalizer.normalizedDisplayName(name)
        let key = CategoryNameNormalizer.comparisonKey(for: normalized)

        return processedLibraryTracks
            .compactMap(\.categoryName)
            .first {
                CategoryNameNormalizer.comparisonKey(for: $0) == key
            }
            ?? normalized
    }

    private var processingPreferencesEnabled: Bool {
        AppPreferences.shouldProcessNewScreenshots &&
        AppPreferences.shouldUseOnDeviceAnalysis
    }

    private func acquireFoundationModel() async throws {
        while isFoundationModelBusy {
            try await Task.sleep(for: .milliseconds(150))
        }
        try Task.checkCancellation()
        isFoundationModelBusy = true
    }

    private func releaseFoundationModel() { isFoundationModelBusy = false }
}
