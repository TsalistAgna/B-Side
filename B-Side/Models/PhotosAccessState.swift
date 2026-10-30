import Photos

nonisolated enum PhotosAccessState: Equatable {
    case notDetermined, authorized, limited, denied, restricted
    init(_ status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized: self = .authorized
        case .limited: self = .limited
        case .denied: self = .denied
        case .restricted: self = .restricted
        @unknown default: self = .restricted
        }
    }
    var canRead: Bool { self == .authorized || self == .limited }
    var label: String {
        switch self {
        case .notDetermined: "Not Set Up"
        case .authorized: "Full Access"
        case .limited: "Limited Access"
        case .denied: "Off"
        case .restricted: "Restricted"
        }
    }
    var title: String {
        switch self {
        case .notDetermined: "Find Your Screenshots"
        case .authorized: "No Screenshots Found"
        case .limited: "No Accessible Screenshots"
        case .denied: "Photos Access Is Off"
        case .restricted: "Photos Access Is Restricted"
        }
    }
    var message: String {
        switch self {
        case .notDetermined: "Side-B uses Photos access to find screenshots you choose to organize."
        case .authorized: "Side-B couldn’t find any screenshots to organize."
        case .limited: "Side-B can’t find screenshots in the Photos currently shared with the app."
        case .denied: "Side-B needs Photos access to find screenshots you can organize."
        case .restricted: "Side-B can’t access Photos because access is restricted on this device."
        }
    }
    var action: String {
        switch self {
        case .notDetermined: "Continue"
        case .authorized: "Check Photos Again"
        case .limited: "Manage Photo Access"
        case .denied: "Open Settings"
        case .restricted: ""
        }
    }
}
