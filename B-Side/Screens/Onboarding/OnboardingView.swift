import SwiftUI
import UIKit

struct OnboardingView: View {
    @ObservedObject var viewModel: HomeViewModel
    let onFinish: (FirstRunDestination) -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var didDiscover = false
    @State private var isWorking = false

    private var offer: FirstRunOrganizationOffer { viewModel.firstRunOrganizationOffer }
    private var title: String {
        if !didDiscover { return "Find Your Screenshots" }
        if !viewModel.photosAccess.canRead { return viewModel.photosAccess.title }
        return offer.title
    }
    private var message: String {
        if !didDiscover { return "Side-B uses Photos access to find screenshots you can organize. Your original screenshots stay in Photos." }
        if !viewModel.photosAccess.canRead { return viewModel.photosAccess.message }
        return offer.message
    }

    var body: some View {
        ZStack {
            Color.bSideBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image("onboardingTurntable")
                        .resizable().scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 160)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)

                    Text(isWorking ? "Finding Your Screenshots…" : title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true)

                    if isWorking {
                        ProgressView("Checking accessible screenshots…")
                    } else {
                        Text(message)
                            .font(.body)
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if didDiscover, case .ready(let count, _) = offer {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Side-B uses on-device intelligence to understand and organize them. Your original screenshots stay in Photos.")
                                if count >= ProcessingPolicy.largeJobThreshold {
                                    Text("This may take a while. You can pause or stop anytime.")
                                }
                                Text("Keep Side-B open while organizing. Screenshots stored only in iCloud may need to be downloaded in Photos before retrying.")
                                    .font(.footnote)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: BSideLayout.radiusMedium))
                        }
                        actions
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, didDiscover, !isWorking else { return }
            perform {
                viewModel.refreshPhotoPermissionStatus()
                await viewModel.refreshFirstRunOffer()
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if !didDiscover {
            PrimaryButton(title: "Continue") {
                perform {
                    await viewModel.requestFirstRunPhotosAccess()
                    didDiscover = true
                }
            }
            secondary("Not Now") { onFinish(.home) }
        } else if !viewModel.photosAccess.canRead {
            if viewModel.photosAccess == .denied {
                PrimaryButton(title: "Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            secondary("Continue to Side-B") { onFinish(.home) }
        } else {
            switch offer {
            case .ready:
                PrimaryButton(title: "Organize Now") {
                    perform {
                        if await viewModel.startFirstRunOrganization() { onFinish(.processing) }
                    }
                }
                secondary("Not Now") { onFinish(.home) }
            case .unavailable, .nothingNew:
                PrimaryButton(title: "Organize Manually") {
                    perform {
                        await viewModel.prepareFirstRunManualOrganization()
                        onFinish(.manual)
                    }
                }
                secondary("Not Now") { onFinish(.home) }
            default:
                PrimaryButton(title: "Continue to Side-B") { onFinish(.home) }
            }
            if viewModel.photosAccess == .limited {
                secondary("Manage Photo Access") { viewModel.managePhotoAccess() }
                secondary("Check Again") {
                    perform { await viewModel.refreshFirstRunOffer() }
                }
            }
        }
    }

    private func secondary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.body.weight(.medium))
            .foregroundStyle(Color.accentText)
            .frame(maxWidth: .infinity, minHeight: 44)
    }

    private func perform(_ operation: @escaping @MainActor () async -> Void) {
        guard !isWorking else { return }
        isWorking = true
        Task { @MainActor in
            await operation()
            isWorking = false
        }
    }
}

#Preview {
    OnboardingView(viewModel: HomeViewModel(), onFinish: { _ in })
}
