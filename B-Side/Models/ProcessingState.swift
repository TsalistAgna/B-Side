import Foundation
import FoundationModels

enum TrackAnalysisStatus: String, Codable { case pending, completed, failed, manual }

struct ProcessingProgress: Equatable {
    var completed = 0
    var failed = 0
    var total = 0
    var handled: Int { completed + failed }
    var remaining: Int { max(0, total - handled) }
}

enum AIUnavailableReason: Equatable {
    case deviceNotEligible, appleIntelligenceNotEnabled, modelNotReady, unknown, analysisDisabled
    var message: String {
        switch self {
        case .analysisDisabled: "On-Device Analysis is off in Side-B Settings. You can turn it on or organize screenshots manually."
        case .deviceNotEligible: "AI organization isn’t available on this device. You can still organize screenshots manually."
        case .appleIntelligenceNotEnabled: "Apple Intelligence isn’t enabled. You can enable it in Settings or organize manually."
        case .modelNotReady: "Apple Intelligence isn’t ready yet. Try again later or organize manually."
        case .unknown: "Apple Intelligence isn’t available right now. You can still organize manually."
        }
    }
    static func current() -> Self? {
        map(SystemLanguageModel.default.availability)
    }
    static func map(_ availability: SystemLanguageModel.Availability) -> Self? {
        switch availability {
        case .available: return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return .deviceNotEligible
            case .appleIntelligenceNotEnabled: return .appleIntelligenceNotEnabled
            case .modelNotReady: return .modelNotReady
            @unknown default: return .unknown
            }
        }
    }
}

enum ProcessingFailure: Error, Equatable {
    case analysis, save
    var message: String {
        switch self {
        case .analysis: "Some screenshots couldn’t be analyzed. Try again or organize them manually."
        case .save: "Side-B couldn’t save your changes. Completed work is safe. Try again before leaving this screen."
        }
    }
}

enum ScreenshotProcessingState: Equatable {
    case idle, preparing
    case cooling(ProcessingProgress)
    case processing(ProcessingProgress), pausing(ProcessingProgress), paused(ProcessingProgress)
    case cancelling(ProcessingProgress), stopped(ProcessingProgress), completed(ProcessingProgress)
    case failed(ProcessingFailure, ProcessingProgress)
    case unavailable(AIUnavailableReason)
    var progress: ProcessingProgress {
        switch self {
        case .cooling(let p), .processing(let p), .pausing(let p), .paused(let p), .cancelling(let p), .stopped(let p), .completed(let p), .failed(_, let p): p
        default: ProcessingProgress()
        }
    }
    var active: Bool {
        switch self {
        case .preparing, .cooling, .processing, .pausing, .paused, .cancelling: true
        default: false
        }
    }
    var title: String {
        switch self {
        case .idle: "Organize Screenshots"
        case .preparing: "Preparing screenshots…"
        case .processing: "Organizing Screenshots"
        case .cooling: "Waiting for your device to cool down"
        case .pausing: "Pausing after this screenshot…"
        case .paused: "Processing Paused"
        case .cancelling: "Stopping…"
        case .stopped: "Processing stopped."
        case .completed: progress.failed == 0 ? "Organization Complete" : "Organization Finished"
        case .failed: "Side-B Couldn’t Finish Organizing"
        case .unavailable: "AI Organization Isn’t Available"
        }
    }
}
