import XCTest
import SwiftData
import FoundationModels
import Photos

@MainActor
final class ProcessingTests: XCTestCase {
    func testStateAndCounts() {
        let progress = ProcessingProgress(completed: 2, failed: 1, total: 5)
        XCTAssertEqual(progress.handled, 3)
        XCTAssertEqual(progress.remaining, 2)
        for state in [ScreenshotProcessingState.preparing, .processing(progress), .pausing(progress), .paused(progress), .cancelling(progress)] {
            XCTAssertTrue(state.active)
        }
        XCTAssertFalse(ScreenshotProcessingState.stopped(progress).active)
        XCTAssertFalse(ScreenshotProcessingState.completed(progress).active)
        XCTAssertEqual(ScreenshotProcessingState.paused(progress).progress, progress)
        XCTAssertEqual(ScreenshotProcessingState.stopped(progress).title, "Processing stopped.")
    }

    func testManualPersistenceAndEditProtection() throws {
        let container = try ModelContainer(for: SavedTrack.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = TrackPersistenceService(context: container.mainContext)
        try service.register(assetID: "one", createdAt: .now)
        XCTAssertEqual(service.findTrack(assetID: "one")?.analysisStatus, .pending)
        try service.markFailed("one")
        XCTAssertEqual(service.findTrack(assetID: "one")?.analysisStatus, .failed)
        try service.save(track: Track(id: "one", createdAt: .now, title: "My title"))
        let saved = try XCTUnwrap(service.findTrack(assetID: "one"))
        XCTAssertEqual(saved.analysisStatus, .manual)
        XCTAssertNil(saved.detailDescription)
        XCTAssertNil(saved.rediscoveryDescription)
        try service.register(assetID: "one", createdAt: .now)
        XCTAssertEqual(service.fetchAll().count, 1)
        XCTAssertTrue(saved.userEdited)
    }

    func testLegacyInference() {
        let saved = SavedTrack(assetID: "legacy", createdAt: .now, title: "Title", rediscoveryDescription: "Rediscover", detailDescription: "Description", tags: [], categoryName: "Trips")
        XCTAssertNil(saved.analysisStatusRaw)
        XCTAssertEqual(saved.analysisStatus, .completed)
        saved.detailDescription = nil
        XCTAssertEqual(saved.analysisStatus, .pending)
    }

    func testAvailabilityCopy() {
        XCTAssertNil(AIUnavailableReason.map(.available))
        XCTAssertEqual(AIUnavailableReason.map(.unavailable(.deviceNotEligible)), .deviceNotEligible)
        XCTAssertEqual(AIUnavailableReason.map(.unavailable(.appleIntelligenceNotEnabled)), .appleIntelligenceNotEnabled)
        XCTAssertEqual(AIUnavailableReason.map(.unavailable(.modelNotReady)), .modelNotReady)
        XCTAssertTrue(AIUnavailableReason.deviceNotEligible.message.contains("this device"))
        XCTAssertTrue(AIUnavailableReason.appleIntelligenceNotEnabled.message.contains("isn’t enabled"))
        XCTAssertTrue(AIUnavailableReason.modelNotReady.message.contains("isn’t ready"))
    }

    private func analysis() -> ScreenshotAnalysis {
        ScreenshotAnalysis(title: "AI title", rediscoveryDescription: "Rediscovery", detailDescription: "Description", tags: [], categoryName: "Ideas")
    }

    func testSaveFailureAndAIProtection() throws {
        let container = try ModelContainer(for: SavedTrack.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = TrackPersistenceService(context: container.mainContext)
        try service.register(assetID: "one", createdAt: .now)
        service.commitOverride = { throw ProcessingFailure.save }
        XCTAssertThrowsError(try service.saveAnalysis(assetID: "one", createdAt: .now, analysis: analysis()))
        XCTAssertEqual(service.findTrack(assetID: "one")?.analysisStatus, .pending)
        service.commitOverride = nil
        try service.save(track: Track(id: "one", createdAt: .now, title: "User title"))
        try service.saveAnalysis(assetID: "one", createdAt: .now, analysis: analysis())
        XCTAssertEqual(service.findTrack(assetID: "one")?.title, "User title")
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Timed out waiting for processing transition")
    }

    func testSequentialPauseResumePartialFailureAndRetry() async throws {
        let container = try ModelContainer(for: SavedTrack.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.configurePersistence(context: container.mainContext)
        vm.permissionStatus = .authorized
        vm.availabilityCheck = { nil }
        vm.screenshotSource = { (0..<3).map { ScreenshotAssetInfo(id: String($0), createdAt: .now) } }
        var calls = 0
        var fail = true
        vm.analysisOperation = { id in
            calls += 1
            try await Task.sleep(for: .milliseconds(60))
            if id == "1" && fail { throw ProcessingFailure.analysis }
            return self.analysis()
        }
        await vm.refreshScopeEstimate()
        vm.startProcessing(scope: .allUnprocessed, limit: nil)
        try await waitUntil { calls == 1 }
        vm.pauseProcessing()
        try await waitUntil { if case .paused = vm.processingState { true } else { false } }
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(calls, 1)
        vm.resumeProcessing()
        try await waitUntil { !vm.processingState.active }
        XCTAssertEqual(vm.processingState.progress.completed, 2)
        XCTAssertEqual(vm.processingState.progress.failed, 1)
        try await Task.sleep(for: .milliseconds(100))
        fail = false
        vm.screenshotSource = { (0..<100).map { ScreenshotAssetInfo(id: String($0), createdAt: .now) } }
        vm.retryProcessing()
        try await waitUntil { !vm.processingState.active }
        XCTAssertEqual(calls, 4)
        XCTAssertEqual(vm.processingState.progress.completed, 1)
        XCTAssertEqual(TrackPersistenceService(context: container.mainContext).fetchAll().count, 3)
    }

    func testCancellationAndUnavailableManualIndex() async throws {
        let container = try ModelContainer(for: SavedTrack.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.configurePersistence(context: container.mainContext)
        vm.permissionStatus = .authorized
        vm.screenshotSource = { [ScreenshotAssetInfo(id: "one", createdAt: .now)] }
        vm.availabilityCheck = { .modelNotReady }
        await vm.refreshScopeEstimate()
        vm.startProcessing(scope: .allUnprocessed, limit: nil)
        try await waitUntil { !vm.processingState.active }
        XCTAssertEqual(vm.processingState, .unavailable(.modelNotReady))
        XCTAssertEqual(vm.processedLibraryTracks.count, 1)
        try await Task.sleep(for: .milliseconds(100))
        vm.availabilityCheck = { nil }
        var started = false
        vm.analysisOperation = { _ in
            started = true
            try await Task.sleep(for: .seconds(10))
            return self.analysis()
        }
        vm.retryProcessing()
        try await waitUntil { started }
        vm.stopProcessing()
        try await waitUntil { !vm.processingState.active }
        guard case .stopped = vm.processingState else { return XCTFail("Cancellation became an error") }
        XCTAssertEqual(vm.processingState.progress.completed, 0)
    }

    func testScopeDatesDeduplicationAndLargeQueues() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!
        let recent = ScreenshotAssetInfo(id: "recent", createdAt: now)
        let old = ScreenshotAssetInfo(id: "old", createdAt: calendar.date(byAdding: .day, value: -40, to: now)!)
        let missing = ScreenshotAssetInfo(id: "missing", createdAt: .distantPast, hasCreationDate: false)
        XCTAssertEqual(ProcessingQueue.select([recent, old, missing, recent], scope: .recent(days: 30), excluded: [], now: now, calendar: calendar).map(\.id), ["recent"])
        XCTAssertTrue(ProcessingQueue.select([recent], scope: .dateRange(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(172800)), excluded: [], now: now).isEmpty)
        XCTAssertTrue(ProcessingQueue.select([recent], scope: .allUnprocessed, excluded: [], limit: 0).isEmpty)
        XCTAssertEqual(ProcessingQueue.select([recent, old, missing], scope: .dateRange(start: now, end: now), excluded: [], now: now, calendar: calendar).count, 1)
        XCTAssertEqual(ProcessingQueue.select([recent, old, missing, recent], scope: .allUnprocessed, excluded: ["recent"], now: now).count, 2)
        for size in [50, 482, 500, 2000] {
            let items = (0..<size).map { ScreenshotAssetInfo(id: String($0), createdAt: now) }
            let queue = ProcessingQueue.select(items + items, scope: .allUnprocessed, excluded: [], limit: 100)
            XCTAssertEqual(queue.count, min(size, 100))
            XCTAssertEqual(Set(queue.map(\.id)).count, queue.count)
        }
    }

    func testExplicitScopeExcludesCompletedManualAndFailed() async throws {
        let container = try ModelContainer(for: SavedTrack.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = TrackPersistenceService(context: container.mainContext)
        try service.saveAnalysis(assetID: "complete", createdAt: .now, analysis: analysis())
        try service.save(track: Track(id: "manual", createdAt: .now, title: "Mine"))
        try service.register(assetID: "failed", createdAt: .now)
        try service.markFailed("failed")
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.configurePersistence(context: container.mainContext)
        vm.permissionStatus = .authorized
        vm.availabilityCheck = { nil }
        vm.screenshotSource = { ["complete", "manual", "failed", "new", "new"].map { ScreenshotAssetInfo(id: $0, createdAt: .now) } }
        var calls = 0
        vm.analysisOperation = { _ in calls += 1; return self.analysis() }
        await vm.refreshScopeEstimate()
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(vm.scopeItems.map(\.id), ["new"])
        vm.startProcessing(scope: .allUnprocessed, limit: 1)
        try await waitUntil { !vm.processingState.active }
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(vm.processingState.progress.handled, 1)
        XCTAssertLessThanOrEqual(vm.processingState.progress.handled, vm.processingState.progress.total)
        await vm.refreshScopeEstimate()
        vm.startProcessing(scope: .allUnprocessed, limit: 1)
        XCTAssertEqual(calls, 1)
    }

    func testPhotosMappingAndDeniedRequestGuard() async {
        XCTAssertEqual(PhotosAccessState(.notDetermined), .notDetermined)
        XCTAssertEqual(PhotosAccessState(.authorized), .authorized)
        XCTAssertEqual(PhotosAccessState(.limited), .limited)
        XCTAssertEqual(PhotosAccessState(.denied), .denied)
        XCTAssertEqual(PhotosAccessState(.restricted), .restricted)
        XCTAssertTrue(PhotosAccessState(.limited).canRead)
        XCTAssertFalse(PhotosAccessState(.denied).canRead)
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.permissionStatus = .notDetermined
        var requests = 0
        vm.authorizationRequest = { requests += 1; return .denied }
        await vm.requestPermission()
        await vm.requestPermission()
        XCTAssertEqual(requests, 1)
        XCTAssertEqual(vm.permissionStatus, .denied)
    }

    func testLocalDeletionBoundaries() throws {
        let container = try ModelContainer(for: SavedTrack.self, SavedCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.configurePersistence(context: container.mainContext)
        let store = TrackPersistenceService(context: container.mainContext)
        try store.save(track: Track(id: "photos-reference", createdAt: .now, title: "Keep me"))
        let collection = vm.createCollection(name: "My collection", vinylStyle: .pink, autoOrganize: false)
        vm.addTrack(trackID: "photos-reference", to: collection.id)
        vm.deleteCollection(id: collection.id)
        XCTAssertNotNil(store.findTrack(assetID: "photos-reference"))
        XCTAssertTrue(CollectionPersistenceService(context: container.mainContext).fetchAll().isEmpty)
        vm.deleteTrackFromBSide(id: "photos-reference")
        XCTAssertEqual(store.findTrack(assetID: "photos-reference")?.isExcluded, true)
        vm.deleteTrackFromBSide(id: "not-yet-indexed")
        XCTAssertEqual(store.findTrack(assetID: "not-yet-indexed")?.isExcluded, true)
        vm.clearAllBSideData()
        XCTAssertTrue(store.fetchAll().isEmpty)
        XCTAssertTrue(vm.processedLibraryTracks.isEmpty)
        XCTAssertTrue(vm.customCollections.isEmpty)
    }

    func testDeletionFailureKeepsRecord() throws {
        let container = try ModelContainer(for: SavedTrack.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TrackPersistenceService(context: container.mainContext)
        try store.save(track: Track(id: "keep", createdAt: .now, title: "Mine"))
        store.commitOverride = { throw ProcessingFailure.save }
        XCTAssertThrowsError(try store.exclude(assetID: "keep"))
        XCTAssertEqual(store.findTrack(assetID: "keep")?.isExcluded, false)
        XCTAssertThrowsError(try store.deleteAll())
        XCTAssertNotNil(store.findTrack(assetID: "keep"))
    }
}

@MainActor
final class AutomaticCollectionSimplificationTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: SavedTrack.self, SavedCollection.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func add(_ id: String, category: String, to service: TrackPersistenceService) throws {
        try service.saveAnalysis(assetID: id, createdAt: .now,
            analysis: ScreenshotAnalysis(title: "Saved idea", rediscoveryDescription: "Worth revisiting",
                detailDescription: "A useful reference", tags: ["Personal detail"], categoryName: category))
    }

    func testArbitraryTopicsMergeWithoutTaxonomyOrMetadataLoss() throws {
        for (names, destination) in [
            (["Travel Memory", "Travel Inspiration", "Travel Planning"], "Travel"),
            (["Bread Recipes", "Bread Technique Notes"], "Bread Baking"),
            (["Raku Glaze Notes", "Ceramic Glaze Inspiration"], "Raku Glazes"),
            (["Ide Kebun", "Catatan Berkebun"], "Kebun Rumah")
        ] {
            let container = try container()
            let service = TrackPersistenceService(context: container.mainContext)
            for (index, name) in names.enumerated() { try add(String(index), category: name, to: service) }
            try add("distinct", category: "Kyoto Residency", to: service)
            let snapshot = service.automaticCollectionCandidates()
            let changed = try service.applyAutomaticCollectionMerges([
                AutomaticCollectionMerge(sourceNames: names, destinationName: destination)
            ], snapshot: snapshot)
            XCTAssertEqual(changed, names.count)
            XCTAssertEqual(Set(service.allCategoryNames()), [destination, "Kyoto Residency"])
            XCTAssertEqual(Set(service.fetchAll().map(\.assetID)), Set(snapshot.map(\.id)))
            for track in service.fetchAll() {
                XCTAssertEqual(track.tags, ["Personal detail"])
                XCTAssertEqual(track.title, "Saved idea")
                XCTAssertEqual(track.analysisStatus, .completed)
                XCTAssertFalse(track.userEdited)
            }
        }
    }

    func testInvalidSourcesCollisionsAndOverlappingGroupsAreRejected() {
        let known: Set<String> = ["Travel Ideas", "Travel Memories", "Pottery"]
        XCTAssertTrue(AutomaticCollectionSimplifier.validatedMapping([
            AutomaticCollectionMerge(sourceNames: ["Travel Ideas", "Invented"], destinationName: "Travel"),
            AutomaticCollectionMerge(sourceNames: ["Travel Ideas", "Travel Memories"], destinationName: "Pottery"),
            AutomaticCollectionMerge(sourceNames: ["Travel Ideas", "Travel Ideas"], destinationName: "Travel")
        ], knownNames: known, protectedNames: []).isEmpty)
        let mapping = AutomaticCollectionSimplifier.validatedMapping([
            AutomaticCollectionMerge(sourceNames: ["Travel Ideas", "Travel Memories"], destinationName: "Travel"),
            AutomaticCollectionMerge(sourceNames: ["Travel Ideas", "Pottery"], destinationName: "Everything")
        ], knownNames: known, protectedNames: [])
        XCTAssertEqual(mapping.count, 2)
        XCTAssertEqual(Set(mapping.values), ["Travel"])
    }

    func testManualEditsAndExclusionsDuringInferenceArePreserved() throws {
        let container = try container()
        let service = TrackPersistenceService(context: container.mainContext)
        try add("a", category: "Travel Ideas", to: service)
        try add("b", category: "Travel Memories", to: service)
        try add("excluded", category: "Travel Ideas", to: service)
        let snapshot = service.automaticCollectionCandidates()
        try service.exclude(assetID: "excluded")
        var edited = try XCTUnwrap(snapshot.first { $0.id == "a" })
        edited.categoryName = "My Trip"
        try service.save(track: edited)
        let changed = try service.applyAutomaticCollectionMerges([
            AutomaticCollectionMerge(sourceNames: ["Travel Ideas", "Travel Memories"], destinationName: "Travel")
        ], snapshot: snapshot)
        XCTAssertEqual(changed, 0)
        XCTAssertEqual(service.findTrack(assetID: "a")?.categoryName, "My Trip")
        XCTAssertEqual(service.findTrack(assetID: "excluded")?.categoryName, "Travel Ideas")
        XCTAssertTrue(AutomaticCollectionSimplifier.validatedMapping([
            AutomaticCollectionMerge(sourceNames: ["My Trip", "Travel Memories"], destinationName: "Travel")
        ], knownNames: ["My Trip", "Travel Memories"], protectedNames: ["My Trip"]).isEmpty)
    }

    func testSaveFailureRollsBackAndClearedLibraryCannotBeRepopulated() throws {
        let container = try container()
        let service = TrackPersistenceService(context: container.mainContext)
        try add("a", category: "Travel Ideas", to: service)
        try add("b", category: "Travel Memories", to: service)
        let snapshot = service.automaticCollectionCandidates()
        let merges = [AutomaticCollectionMerge(sourceNames: ["Travel Ideas", "Travel Memories"], destinationName: "Travel")]
        service.commitOverride = { throw ProcessingFailure.save }
        XCTAssertThrowsError(try service.applyAutomaticCollectionMerges(merges, snapshot: snapshot))
        XCTAssertEqual(Set(service.allCategoryNames()), ["Travel Ideas", "Travel Memories"])
        service.commitOverride = nil
        try service.deleteAll()
        XCTAssertEqual(try service.applyAutomaticCollectionMerges(merges, snapshot: snapshot), 0)
        XCTAssertTrue(service.fetchAll().isEmpty)
    }

    func testExistingCollectionCleanupUpdatesHomeAndIsIdempotent() async throws {
        let container = try container()
        let service = TrackPersistenceService(context: container.mainContext)
        try add("a", category: "Bread Recipes", to: service)
        try add("b", category: "Bread Technique Notes", to: service)
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.configurePersistence(context: container.mainContext)
        vm.availabilityCheck = { nil }
        var calls = 0
        vm.collectionSimplificationOperation = { _ in
            calls += 1
            return [AutomaticCollectionMerge(sourceNames: ["Bread Recipes", "Bread Technique Notes"], destinationName: "Bread Baking")]
        }
        await vm.simplifyAutomaticCollections()
        XCTAssertEqual(vm.collections.map(\.name), ["Bread Baking"])
        XCTAssertEqual(Set(vm.tracks.compactMap(\.categoryName)), ["Bread Baking"])
        await vm.simplifyAutomaticCollections()
        XCTAssertEqual(calls, 1)
        XCTAssertFalse(vm.isSimplifyingCollections)
    }
}

extension AutomaticCollectionSimplificationTests {
    func testNewProcessingAutomaticallyConsolidatesRelatedTopics() async throws {
        let container = try container()
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.configurePersistence(context: container.mainContext)
        vm.permissionStatus = .authorized
        vm.availabilityCheck = { nil }
        vm.screenshotSource = { [ScreenshotAssetInfo(id: "a", createdAt: .now), ScreenshotAssetInfo(id: "b", createdAt: .now)] }
        vm.analysisOperation = { id in
            ScreenshotAnalysis(title: "Ceramic reference", rediscoveryDescription: "Worth revisiting",
                detailDescription: "A glaze reference", tags: ["Glaze"],
                categoryName: id == "a" ? "Glaze Experiments" : "Glaze Inspiration")
        }
        var consolidationCalls = 0
        vm.collectionSimplificationOperation = { _ in
            consolidationCalls += 1
            return [AutomaticCollectionMerge(sourceNames: ["Glaze Experiments", "Glaze Inspiration"], destinationName: "Ceramic Glazes")]
        }
        await vm.refreshScopeEstimate()
        vm.startProcessing(scope: .allUnprocessed, limit: nil)
        for _ in 0..<200 {
            if !vm.processingState.active { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertFalse(vm.processingState.active)
        XCTAssertEqual(consolidationCalls, 1)
        XCTAssertEqual(vm.collections.map(\.name), ["Ceramic Glazes"])
    }
}

@MainActor
final class FirstRunOrganizationTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: SavedTrack.self, SavedCollection.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
    private func model(_ container: ModelContainer, status: PHAuthorizationStatus = .authorized) -> HomeViewModel {
        let vm = HomeViewModel(rediscoveryNotifications: DailyRediscoveryNotificationManager(client: FakeRediscoveryClient()))
        vm.configurePersistence(context: container.mainContext)
        vm.permissionStatus = status
        vm.photoAuthorizationStatus = { status }
        vm.availabilityCheck = { nil }
        return vm
    }
    private func analysis() -> ScreenshotAnalysis {
        ScreenshotAnalysis(title: "Idea", rediscoveryDescription: "Worth revisiting", detailDescription: "A reference", tags: [], categoryName: "Ideas")
    }
    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<500 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Timed out waiting for processing")
    }

    func testPhotosGrantDiscoversAllDatesWithoutStartingAI() async throws {
        let container = try container()
        let vm = model(container, status: .notDetermined)
        var authorization: PHAuthorizationStatus = .notDetermined
        var permissionCalls = 0
        vm.photoAuthorizationStatus = { authorization }
        vm.authorizationRequest = { permissionCalls += 1; authorization = .authorized; return .authorized }
        let oldDate = Date(timeIntervalSince1970: 1)
        vm.screenshotSource = { (0..<482).map { ScreenshotAssetInfo(id: String($0), createdAt: oldDate) } }
        var analysisCalls = 0
        vm.analysisOperation = { _ in analysisCalls += 1; return self.analysis() }
        await vm.requestFirstRunPhotosAccess()
        XCTAssertEqual(permissionCalls, 1)
        XCTAssertEqual(vm.screenshotDiscovery.accessible, 482)
        XCTAssertEqual(vm.screenshotDiscovery.eligible, 482)
        XCTAssertEqual(vm.firstRunOrganizationOffer, .ready(count: 482, limited: false))
        XCTAssertEqual(vm.processingState, .idle)
        XCTAssertEqual(analysisCalls, 0)
        XCTAssertTrue(TrackPersistenceService(context: container.mainContext).fetchAll().isEmpty)
    }

    func testEligibilityDistinguishesAccessibleOrganizedFailedManualExcludedAndDuplicates() async throws {
        let container = try container()
        let service = TrackPersistenceService(context: container.mainContext)
        try service.saveAnalysis(assetID: "completed", createdAt: .now, analysis: analysis())
        try service.save(track: Track(id: "manual", createdAt: .now))
        try service.register(assetID: "failed", createdAt: .now)
        try service.markFailed("failed")
        try service.exclude(assetID: "excluded")
        try service.register(assetID: "pending", createdAt: .now)
        let vm = model(container)
        vm.screenshotSource = { ["completed", "manual", "failed", "excluded", "pending", "new", "new"].map { ScreenshotAssetInfo(id: $0, createdAt: .now) } }
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.screenshotDiscovery, ScreenshotDiscoverySummary(accessible: 6, organized: 2, failed: 1, excluded: 1, eligible: 2))
        XCTAssertEqual(Set(vm.scopeItems.map(\.id)), ["pending", "new"])
    }

    func testLimitedAccessCountsOnlyAccessibleItems() async throws {
        let container = try container()
        let service = TrackPersistenceService(context: container.mainContext)
        try service.saveAnalysis(assetID: "not-shared", createdAt: .now, analysis: analysis())
        let vm = model(container, status: .limited)
        vm.screenshotSource = { [ScreenshotAssetInfo(id: "shared", createdAt: .now)] }
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.screenshotDiscovery.accessible, 1)
        XCTAssertEqual(vm.screenshotDiscovery.organized, 0)
        XCTAssertEqual(vm.firstRunOrganizationOffer, .ready(count: 1, limited: true))
        XCTAssertTrue(vm.firstRunOrganizationOffer.message.contains("accessible"))
    }

    func testZeroCaughtUpAndFailedOnlyHaveDifferentStates() async throws {
        let container = try container()
        let service = TrackPersistenceService(context: container.mainContext)
        let vm = model(container)
        vm.screenshotSource = { [] }
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.firstRunOrganizationOffer, .noScreenshots(limited: false))
        vm.photoAuthorizationStatus = { .limited }
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.firstRunOrganizationOffer, .noScreenshots(limited: true))
        try service.saveAnalysis(assetID: "one", createdAt: .now, analysis: analysis())
        vm.screenshotSource = { [ScreenshotAssetInfo(id: "one", createdAt: .now)] }
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.firstRunOrganizationOffer, .caughtUp)
        let started = await vm.startFirstRunOrganization()
        XCTAssertFalse(started)
        try service.markFailed("one")
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.firstRunOrganizationOffer, .nothingNew)
    }

    func testNotNowPersistsCompletionWithoutProcessingOrIndexing() async throws {
        let container = try container()
        let vm = model(container)
        vm.screenshotSource = { [ScreenshotAssetInfo(id: "one", createdAt: .now)] }
        var analysisCalls = 0
        vm.analysisOperation = { _ in analysisCalls += 1; return self.analysis() }
        await vm.refreshFirstRunOffer()
        let suite = "FirstRunTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        // Same completion operation used by Not Now in ContentView.
        AppPreferences.completeOnboarding(in: defaults)
        XCTAssertTrue(UserDefaults(suiteName: suite)!.bool(forKey: AppPreferences.hasFinishedOnboardingKey))
        XCTAssertEqual(vm.processingState, .idle)
        XCTAssertEqual(analysisCalls, 0)
        XCTAssertTrue(TrackPersistenceService(context: container.mainContext).fetchAll().isEmpty)
        vm.clearAllBSideData()
        XCTAssertTrue(defaults.bool(forKey: AppPreferences.hasFinishedOnboardingKey))
    }

    func testOrganizeNowQueuesAll2000MetadataJobsAndStartsWithoutSecondConfirmation() async throws {
        let container = try container()
        let vm = model(container)
        vm.screenshotSource = { (0..<2000).map { ScreenshotAssetInfo(id: String($0), createdAt: .distantPast) } }
        var analysisCalls = 0
        vm.analysisOperation = { _ in
            analysisCalls += 1
            try await Task.sleep(for: .seconds(30))
            return self.analysis()
        }
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.screenshotDiscovery.eligible, 2000)
        XCTAssertEqual(analysisCalls, 0)
        let started = await vm.startFirstRunOrganization()
        XCTAssertTrue(started)
        XCTAssertTrue(vm.processingState.active)
        try await waitUntil { analysisCalls == 1 }
        XCTAssertEqual(vm.processingState.progress.total, 2000)
        XCTAssertEqual(vm.remainingInScope, 0)
        XCTAssertEqual(TrackPersistenceService(context: container.mainContext).fetchAll().count, 2000)
        // Only the first inference is in flight; discovery never supplies UIImages.
        XCTAssertEqual(analysisCalls, 1)
        let duplicateStart = await vm.startFirstRunOrganization()
        XCTAssertFalse(duplicateStart)
        vm.stopProcessing()
        try await waitUntil { !vm.processingState.active }
    }

    func testAvailabilityFallbackDoesNotStartAndManualPathDoesNotAnalyze() async throws {
        for reason in [AIUnavailableReason.deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady] {
            let container = try container()
            let vm = model(container)
            vm.screenshotSource = { [ScreenshotAssetInfo(id: "one", createdAt: .now)] }
            vm.availabilityCheck = { reason }
            var analysisCalls = 0
            vm.analysisOperation = { _ in analysisCalls += 1; return self.analysis() }
            await vm.refreshFirstRunOffer()
            XCTAssertEqual(vm.firstRunOrganizationOffer, .unavailable(reason))
            let started = await vm.startFirstRunOrganization()
            XCTAssertFalse(started)
            await vm.prepareFirstRunManualOrganization()
            XCTAssertEqual(vm.processedLibraryTracks.count, 1)
            XCTAssertEqual(analysisCalls, 0)
        }
    }

    func testConfirmRechecksNewlyCompletedTracksAndRevokedPermission() async throws {
        let container = try container()
        let service = TrackPersistenceService(context: container.mainContext)
        let vm = model(container)
        vm.screenshotSource = { [ScreenshotAssetInfo(id: "one", createdAt: .now)] }
        await vm.refreshFirstRunOffer()
        try service.saveAnalysis(assetID: "one", createdAt: .now, analysis: analysis())
        let started = await vm.startFirstRunOrganization()
        XCTAssertFalse(started)
        XCTAssertEqual(vm.firstRunOrganizationOffer, .caughtUp)
        vm.photoAuthorizationStatus = { .denied }
        await vm.refreshFirstRunOffer()
        XCTAssertEqual(vm.firstRunOrganizationOffer, .needsPhotos)
        XCTAssertEqual(vm.screenshotDiscovery.accessible, 0)
        XCTAssertTrue(vm.scopeItems.isEmpty)
    }
}
