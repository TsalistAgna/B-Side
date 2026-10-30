import SwiftUI
import Photos

struct EmptyHomeView: View {
    let permissionStatus: PHAuthorizationStatus
    let onAddScreenshots: () -> Void
    private var access: PhotosAccessState { PhotosAccessState(permissionStatus) }
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.decorativeAccent)
                    .accessibilityHidden(true)
                Text(access.title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Text(access.message).font(.body)
                Text("Your original screenshots stay in Photos.").font(.footnote)
                if access != .restricted {
                    PrimaryButton(title: access.action, action: onAddScreenshots)
                }
            }
            .foregroundStyle(Color.textPrimary)
            .multilineTextAlignment(.center)
            .padding(24)
        }
    }
}
