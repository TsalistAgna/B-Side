import Combine
import Foundation
import UserNotifications

/// Only the system adapter touches UserNotifications; tests inject an in-memory client.
@MainActor
protocol RediscoveryNotificationClient {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws
    func pendingRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func cancelRediscovery()
}

@MainActor
final class SystemRediscoveryNotificationClient: RediscoveryNotificationClient {
    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { continuation.resume(returning: $0.authorizationStatus) }
        }
    }

    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }

    func cancelRediscovery() {
        center.removePendingNotificationRequests(withIdentifiers: [DailyRediscoveryNotificationManager.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [DailyRediscoveryNotificationManager.identifier])
    }
}

@MainActor
final class DailyRediscoveryNotificationManager: ObservableObject {
    static let shared = DailyRediscoveryNotificationManager(client: SystemRediscoveryNotificationClient())
    static let identifier = "sideb.dailyRediscovery"
    static let defaultHour = 10
    static let defaultMinute = 0
    static let preferenceKey = "dailyRediscoveryNotificationsEnabled"

    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined
    @Published private(set) var preferenceEnabled: Bool
    @Published private(set) var isScheduled = false
    @Published private(set) var hasEligibleTracks = false
    @Published private(set) var isUpdating = false
    @Published var showPermissionExplanation = false
    @Published private(set) var schedulingError: String?
    // Retained until MainTabView exists, including cold launches through a notification.
    @Published var shouldOpenHome = false

    private let client: RediscoveryNotificationClient
    private let defaults: UserDefaults
    private var pendingOperation: Task<Void, Never>?
    private var operationCount = 0

    init(client: RediscoveryNotificationClient, defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
        preferenceEnabled = defaults.bool(forKey: Self.preferenceKey)
    }

    var permissionAllowsNotifications: Bool {
        switch authorization {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined, .denied: return false
        @unknown default: return false
        }
    }

    var toggleIsOn: Bool { preferenceEnabled && permissionAllowsNotifications }

    var statusText: String {
        if let schedulingError { return schedulingError }
        if authorization == .denied { return "Notifications are off in iOS Settings." }
        if preferenceEnabled && !hasEligibleTracks { return "Reminders are paused until there’s a Track to rediscover." }
        if isScheduled { return "One reminder daily at 10:00 AM. Delivery follows your iOS notification settings." }
        return "Get one gentle reminder when your daily screenshot rediscovery is ready."
    }

    /// Serialize system reads/writes so an older refresh cannot undo a later toggle or clear.
    @discardableResult
    private func enqueue(_ operation: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        let previous = pendingOperation
        operationCount += 1
        isUpdating = true
        let task = Task { @MainActor in
            await previous?.value
            await operation()
            operationCount -= 1
            isUpdating = operationCount > 0
        }
        pendingOperation = task
        return task
    }

    @discardableResult
    func refresh() -> Task<Void, Never> {
        enqueue { await self.reconcile() }
    }

    @discardableResult
    func updateEligibility(_ hasTracks: Bool) -> Task<Void, Never> {
        enqueue {
            self.hasEligibleTracks = hasTracks
            await self.reconcile()
        }
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> Task<Void, Never> {
        enqueue {
            self.schedulingError = nil
            if !enabled {
                self.storePreference(false)
                await self.reconcile()
                return
            }
            self.authorization = await self.client.authorizationStatus()
            if self.authorization == .notDetermined {
                do { try await self.client.requestAuthorization() }
                catch {
                    self.storePreference(false)
                    await self.reconcile()
                    self.schedulingError = "Side-B couldn’t enable reminders. Please try again."
                    return
                }
                self.authorization = await self.client.authorizationStatus()
            }
            self.storePreference(self.permissionAllowsNotifications)
            self.showPermissionExplanation = !self.permissionAllowsNotifications
            await self.reconcile()
        }
    }

    private func storePreference(_ enabled: Bool) {
        preferenceEnabled = enabled
        defaults.set(enabled, forKey: Self.preferenceKey)
    }

    private func reconcile() async {
        authorization = await client.authorizationStatus()
        schedulingError = nil
        guard preferenceEnabled, permissionAllowsNotifications, hasEligibleTracks else {
            client.cancelRediscovery()
            isScheduled = false
            return
        }
        let pending = await client.pendingRequests()
        if !pending.contains(where: Self.isProductionRequest) {
            do { try await client.add(Self.makeRequest()) }
            catch {
                client.cancelRediscovery()
                isScheduled = false
                storePreference(false)
                schedulingError = "Side-B couldn’t schedule your reminder. Turn it on to try again."
                return
            }
        }
        isScheduled = await client.pendingRequests().contains(where: Self.isProductionRequest)
        if !isScheduled {
            storePreference(false)
            schedulingError = "Side-B couldn’t schedule your reminder. Turn it on to try again."
        }
    }

    static func makeRequest() -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Today’s Rediscovery"
        content.body = "A screenshot from your Side-B is ready to revisit."
        content.sound = .default
        content.interruptionLevel = .active
        content.userInfo = ["destination": identifier]
        let time = DateComponents(hour: defaultHour, minute: defaultMinute)
        return UNNotificationRequest(identifier: identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: time, repeats: true))
    }

    private static func isProductionRequest(_ request: UNNotificationRequest) -> Bool {
        guard request.identifier == identifier,
              let trigger = request.trigger as? UNCalendarNotificationTrigger else { return false }
        let expected = makeRequest()
        return trigger.repeats && trigger.dateComponents == DateComponents(hour: defaultHour, minute: defaultMinute)
            && request.content.title == expected.content.title && request.content.body == expected.content.body
            && request.content.interruptionLevel == .active && request.content.attachments.isEmpty
            && request.content.badge == nil && request.content.userInfo as NSDictionary == expected.content.userInfo as NSDictionary
    }
}
