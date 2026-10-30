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
        let vm = HomeViewModel()
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
        let vm = HomeViewModel()
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
        let vm = HomeViewModel()
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
        let vm = HomeViewModel()
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
        let vm = HomeViewModel()
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
