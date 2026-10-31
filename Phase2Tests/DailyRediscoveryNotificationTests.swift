import XCTest
import UserNotifications
import SwiftData

@MainActor
final class FakeRediscoveryClient: RediscoveryNotificationClient {
    var status: UNAuthorizationStatus = .notDetermined
    var permissionResult: UNAuthorizationStatus = .authorized
    var permissionRequests = 0
    var addCount = 0
    var requests: [String: UNNotificationRequest] = [:]
    var failAdd = false
    var addDelay = false

    func authorizationStatus() async -> UNAuthorizationStatus { status }
    func requestAuthorization() async throws {
        permissionRequests += 1
        status = permissionResult
    }
    func pendingRequests() async -> [UNNotificationRequest] { Array(requests.values) }
    func add(_ request: UNNotificationRequest) async throws {
        if addDelay { try await Task.sleep(for: .milliseconds(20)) }
        if failAdd { throw NSError(domain: "test", code: 1) }
        addCount += 1
        requests[request.identifier] = request
    }
    func cancelRediscovery() { requests.removeValue(forKey: DailyRediscoveryNotificationManager.identifier) }
}

@MainActor
final class DailyRediscoveryNotificationTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private var client: FakeRediscoveryClient!
    private var manager: DailyRediscoveryNotificationManager!

    override func setUp() async throws {
        suite = "DailyRediscoveryTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        client = FakeRediscoveryClient()
        manager = DailyRediscoveryNotificationManager(client: client, defaults: defaults)
    }

    override func tearDown() async throws {
        await manager.refresh().value
        defaults.removePersistentDomain(forName: suite)
    }

    func testFirstEnableRequestsPermissionAndSchedulesExactlyOnePrivateDailyReminder() async throws {
        await manager.updateEligibility(true).value
        XCTAssertEqual(client.permissionRequests, 0)
        await manager.setEnabled(true).value
        XCTAssertEqual(client.permissionRequests, 1)
        XCTAssertTrue(manager.preferenceEnabled)
        XCTAssertTrue(manager.toggleIsOn)
        XCTAssertTrue(manager.isScheduled)
        XCTAssertEqual(client.requests.count, 1)
        let request = try XCTUnwrap(client.requests[DailyRediscoveryNotificationManager.identifier])
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertTrue(trigger.repeats)
        XCTAssertEqual(trigger.dateComponents, DateComponents(hour: 10, minute: 0))
        XCTAssertNil(trigger.dateComponents.timeZone)
        XCTAssertEqual(request.content.interruptionLevel, .active)
        XCTAssertEqual(request.content.title, "Today’s Rediscovery")
        XCTAssertEqual(request.content.body, "A screenshot from your Side-B is ready to revisit.")
        XCTAssertTrue(request.content.attachments.isEmpty)
        XCTAssertNil(request.content.badge)
        XCTAssertEqual(request.content.userInfo.count, 1)
        XCTAssertEqual(request.content.userInfo["destination"] as? String, DailyRediscoveryNotificationManager.identifier)
        XCTAssertNotNil(request.content.sound)
    }

    func testDeniedFirstRequestKeepsPreferenceOff() async {
        client.permissionResult = .denied
        await manager.updateEligibility(true).value
        await manager.setEnabled(true).value
        XCTAssertEqual(client.permissionRequests, 1)
        XCTAssertFalse(manager.preferenceEnabled)
        XCTAssertTrue(manager.showPermissionExplanation)
        XCTAssertTrue(client.requests.isEmpty)
        await manager.setEnabled(true).value
        XCTAssertEqual(client.permissionRequests, 1)
    }

    func testAlreadyDeniedNeverRequestsAgain() async {
        client.status = .denied
        await manager.setEnabled(true).value
        XCTAssertEqual(client.permissionRequests, 0)
        XCTAssertFalse(manager.toggleIsOn)
        XCTAssertFalse(manager.preferenceEnabled)
        XCTAssertTrue(client.requests.isEmpty)
    }

    func testOffOnlyRemovesFeatureRequestAndPreservesAuthorization() async {
        client.status = .authorized
        let other = UNNotificationRequest(identifier: "another.feature", content: UNMutableNotificationContent(), trigger: nil)
        client.requests[other.identifier] = other
        await manager.updateEligibility(true).value
        await manager.setEnabled(true).value
        await manager.setEnabled(false).value
        XCTAssertEqual(Set(client.requests.keys), ["another.feature"])
        XCTAssertEqual(client.status, .authorized)
        XCTAssertFalse(manager.preferenceEnabled)
    }

    func testRelaunchRestoresPreferenceAndRepairsMissingRequestWithoutDuplicates() async {
        client.status = .authorized
        defaults.set(true, forKey: DailyRediscoveryNotificationManager.preferenceKey)
        let relaunched = DailyRediscoveryNotificationManager(client: client, defaults: defaults)
        await relaunched.updateEligibility(true).value
        await relaunched.refresh().value
        XCTAssertTrue(relaunched.toggleIsOn)
        XCTAssertEqual(client.addCount, 1)
        client.requests.removeAll()
        await relaunched.refresh().value
        XCTAssertEqual(client.addCount, 2)
        XCTAssertEqual(client.requests.count, 1)
    }

    func testExternalRevocationAndRestorationRefreshDisplayedState() async {
        client.status = .authorized
        await manager.updateEligibility(true).value
        await manager.setEnabled(true).value
        client.status = .denied
        await manager.refresh().value
        XCTAssertFalse(manager.toggleIsOn)
        XCTAssertFalse(manager.isScheduled)
        XCTAssertTrue(manager.preferenceEnabled)
        XCTAssertTrue(client.requests.isEmpty)
        client.status = .authorized
        await manager.refresh().value
        XCTAssertTrue(manager.toggleIsOn)
        XCTAssertTrue(manager.isScheduled)
    }

    func testZeroTracksThenContentThenEmptyPreservesPreference() async {
        client.status = .authorized
        await manager.setEnabled(true).value
        XCTAssertTrue(manager.preferenceEnabled)
        XCTAssertFalse(manager.isScheduled)
        XCTAssertTrue(client.requests.isEmpty)
        await manager.updateEligibility(true).value
        XCTAssertTrue(manager.isScheduled)
        await manager.updateEligibility(false).value
        XCTAssertTrue(manager.preferenceEnabled)
        XCTAssertFalse(manager.isScheduled)
        XCTAssertTrue(client.requests.isEmpty)
    }

    func testClearSideBDataCancelsReminderThroughHomeTrackLifecycle() async throws {
        client.status = .authorized
        let container = try ModelContainer(for: SavedTrack.self, SavedCollection.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let vm = HomeViewModel(rediscoveryNotifications: manager)
        vm.configurePersistence(context: container.mainContext)
        vm.tracks = [Track(id: "test", createdAt: .now)]
        await manager.setEnabled(true).value
        XCTAssertTrue(manager.isScheduled)
        vm.clearAllBSideData()
        await manager.refresh().value
        XCTAssertTrue(vm.tracks.isEmpty)
        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertTrue(manager.preferenceEnabled)
        XCTAssertEqual(client.status, .authorized)
    }

    func testAllowedSystemPermissionAloneDoesNotOptIn() async {
        client.status = .authorized
        await manager.updateEligibility(true).value
        XCTAssertFalse(manager.toggleIsOn)
        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertEqual(client.permissionRequests, 0)
    }

    func testProvisionalAndEphemeralAreRecognizedWithoutRequestingUpgrade() async {
        for status in [UNAuthorizationStatus.provisional, .ephemeral] {
            client.status = status
            await manager.updateEligibility(true).value
            await manager.setEnabled(true).value
            XCTAssertTrue(manager.isScheduled)
            XCTAssertEqual(client.permissionRequests, 0)
        }
    }

    func testSchedulingFailureDoesNotLeaveToggleOn() async {
        client.status = .authorized
        client.failAdd = true
        await manager.updateEligibility(true).value
        await manager.setEnabled(true).value
        XCTAssertFalse(manager.toggleIsOn)
        XCTAssertFalse(manager.isScheduled)
        XCTAssertNotNil(manager.schedulingError)
    }

    func testOffWinsWhenRefreshAndSlowSchedulingOverlap() async {
        client.status = .authorized
        client.addDelay = true
        await manager.updateEligibility(true).value
        let enable = manager.setEnabled(true)
        let refresh = manager.refresh()
        let disable = manager.setEnabled(false)
        await enable.value
        await refresh.value
        await disable.value
        XCTAssertFalse(manager.preferenceEnabled)
        XCTAssertFalse(manager.isScheduled)
        XCTAssertFalse(manager.isUpdating)
        XCTAssertTrue(client.requests.isEmpty)
    }
}
