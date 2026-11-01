import Foundation

nonisolated enum ProcessingPolicy {
    static let recentDays = 30
    static let largeJobThreshold = 250
    // Shared model gate serializes inference; avoid speculative parallel sessions.
    static let maxConcurrentAnalysisTasks = 1
    static let imageWidth = 1200
    static let imageHeight = 2400
}

nonisolated enum ProcessingScope: Equatable, Sendable {
    case recent(days: Int)
    case dateRange(start: Date, end: Date)
    case allUnprocessed

    func interval(now: Date = .now, calendar: Calendar = .current) -> DateInterval? {
        switch self {
        case .allUnprocessed: return nil
        case .recent(let days):
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            let start = calendar.date(byAdding: .day, value: -max(1, days) + 1, to: calendar.startOfDay(for: now))!
            return DateInterval(start: start, end: end)
        case .dateRange(let start, let end):
            guard calendar.startOfDay(for: start) <= calendar.startOfDay(for: end) else { return DateInterval(start: start, duration: 0) }
            return DateInterval(start: calendar.startOfDay(for: start), end: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end))!)
        }
    }

    func contains(_ item: ScreenshotAssetInfo, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let interval = interval(now: now, calendar: calendar) else { return true }
        guard item.hasCreationDate else { return false }
        return item.createdAt >= interval.start && item.createdAt < interval.end && item.createdAt <= now
    }
}

nonisolated enum ProcessingQueue {
    static func select(_ items: [ScreenshotAssetInfo], scope: ProcessingScope, excluded: Set<String>, limit: Int? = nil, now: Date = .now, calendar: Calendar = .current) -> [ScreenshotAssetInfo] {
        var seen = Set<String>()
        let eligible = items.filter { !excluded.contains($0.id) && scope.contains($0, now: now, calendar: calendar) && seen.insert($0.id).inserted }
            .sorted { $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt > $1.createdAt }
        return Array(eligible.prefix(limit.map { max(0, $0) } ?? eligible.count))
    }
}

/// Counts describe only screenshots accessible under the current Photos permission.
struct ScreenshotDiscoverySummary: Equatable {
    var accessible = 0
    var organized = 0
    var failed = 0
    var excluded = 0
    var eligible = 0

    var allOrganized: Bool { accessible > 0 && organized == accessible }
}

enum FirstRunOrganizationOffer: Equatable {
    case needsPhotos
    case noScreenshots(limited: Bool)
    case caughtUp
    case nothingNew
    case unavailable(AIUnavailableReason)
    case ready(count: Int, limited: Bool)

    var title: String {
        switch self {
        case .needsPhotos: "Find Your Screenshots"
        case .noScreenshots(let limited): limited ? "No Accessible Screenshots" : "No Screenshots Found"
        case .caughtUp: "You’re All Caught Up"
        case .nothingNew: "Nothing New to Organize"
        case .unavailable: "AI Organization Isn’t Available"
        case .ready: "Organize Your Screenshots?"
        }
    }

    var message: String {
        switch self {
        case .needsPhotos: "Side-B uses Photos access to find screenshots you can organize."
        case .noScreenshots(let limited): limited
            ? "Side-B can’t find screenshots in the Photos currently shared with the app."
            : "Side-B couldn’t find any screenshots to organize."
        case .caughtUp: "All of your available screenshots are already organized in Side-B."
        case .nothingNew: "There are no new screenshots ready for AI organization. You can review saved Tracks or retry screenshots that need attention from Settings."
        case .unavailable(let reason): reason.message
        case .ready(let count, let limited): "Side-B found \(count.formatted()) \(limited ? "accessible " : "")screenshots ready to organize."
        }
    }
}

enum FirstRunDestination {
    case home, processing, manual
}
