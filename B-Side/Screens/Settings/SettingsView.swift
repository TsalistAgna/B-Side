//
//  SettingsView.swift
//  B-Side
//

import Photos
import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject private var notifications: DailyRediscoveryNotificationManager

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        self.notifications = viewModel.rediscoveryNotifications
    }

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(AppPreferences.processNewScreenshotsKey)
    private var processNewScreenshots = true

    @AppStorage(AppPreferences.autoOrganizeNewTracksKey)
    private var autoOrganizeNewTracks = true

    @AppStorage(AppPreferences.onDeviceAnalysisKey)
    private var onDeviceAnalysis = true

    @State private var showOnDeviceAIInfo = false
    @State private var showManageData = false
    @State private var showAbout = false
    @State private var explainPhotos = false
    @State private var showProcessingScope = false
    @State private var showManualOrganization = false

    private let privacyPolicyURL = URL(string: "https://side-b-page.vercel.app/privacy")

    var body: some View {
        ZStack {
            Color.bSideBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    Text("Settings")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.textPrimary)

                    permissionSection
                    notificationSection
                    organizationSection
                    analysisSection
                    privacySection
                    generalSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, BSideLayout.spacingXL)
            }
        }
        .task { await notifications.refresh().value }
        .alert("Notifications Are Off", isPresented: $notifications.showPermissionExplanation) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("You can enable notifications in Settings to receive your Daily Rediscovery reminder.")
        }
        .sheet(isPresented: $showProcessingScope) {
            ProcessingScopeView(viewModel: viewModel)
        }
        .sheet(isPresented: $showManualOrganization) {
            ManualOrganizationView(viewModel: viewModel)
        }
        .sheet(isPresented: $showOnDeviceAIInfo) {
            OnDeviceAIInfoSheet()
                .presentationDetents([.fraction(0.68), .large])
                .presentationCornerRadius(BSideLayout.radiusSheet)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showManageData) {
            ManageScreenshotDataSheet(
                trackCount: viewModel.processedLibraryTracks.count,
                collectionCount: viewModel.customCollections.count,
                onClear: viewModel.clearAllBSideData
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationCornerRadius(BSideLayout.radiusSheet)
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $explainPhotos) {
            EmptyHomeView(permissionStatus: .notDetermined) {
                explainPhotos = false
                Task { await viewModel.requestPermission() }
            }.presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAbout) {
            AboutBSideSheet()
                .presentationDetents([.fraction(0.55), .large])
                .presentationCornerRadius(BSideLayout.radiusSheet)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: processNewScreenshots) {
            viewModel.refreshProcessingForPreferences()
        }
        .onChange(of: onDeviceAnalysis) {
            viewModel.refreshProcessingForPreferences()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                viewModel.refreshPhotoPermissionStatus()
            }
        }
    }

    private var notificationSection: some View {
        SettingsSection(title: "Notifications") {
            SettingsToggleRow(
                icon: "bell",
                title: "Daily Rediscovery",
                subtitle: "Get one gentle reminder when your daily screenshot rediscovery is ready.",
                isOn: Binding(
                    get: { notifications.toggleIsOn },
                    set: { notifications.setEnabled($0) }
                )
            )
            .disabled(notifications.isUpdating)

            Text(notifications.statusText)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BSideLayout.radiusMedium)
                .padding(.bottom, 14)
        }
    }

    private var permissionSection: some View {
        SettingsSection(title: "Photos") {
            SettingsNavigationRow(
                icon: "photo",
                title: "Photos Access",
                detail: photoPermissionText,
                action: handlePhotoPermission
            )
            .disabled(viewModel.photosAccess == .restricted)

        }
    }

    private var organizationSection: some View {
        VStack(alignment: .leading, spacing: BSideLayout.spacingSM) {
            SettingsSection(title: "Screenshot Organization") {
                SettingsNavigationRow(
                    icon: "photo.stack",
                    title: "Choose What to Organize",
                    subtitle: "Select which screenshots Side-B should organize."
                ) {
                    showProcessingScope = true
                }
                .disabled(viewModel.processingState.active)

                SettingsDivider()

                SettingsNavigationRow(
                    icon: "square.and.pencil",
                    title: "Organize Manually",
                    subtitle: "Choose and organize screenshots yourself."
                ) {
                    viewModel.organizeManually()
                    showManualOrganization = true
                }
            }

            if viewModel.processingState != .idle {
                ProcessingStatusView(viewModel: viewModel)
            }
        }
    }

    private var analysisSection: some View {
        SettingsSection(title: "AI Organization") {
            SettingsToggleRow(
                icon: "rectangle.stack",
                title: "Process New Screenshots",
                subtitle: "Discover screenshots recently added to Photos.",
                isOn: $processNewScreenshots
            )

            SettingsDivider()

            SettingsToggleRow(
                icon: "wand.and.stars",
                title: "Auto-Organize New Tracks",
                subtitle: "Automatically place analyzed Tracks into relevant collections.",
                isOn: $autoOrganizeNewTracks
            )
            SettingsDivider()

            SettingsToggleRow(
                icon: "sparkles",
                title: "On-Device Analysis",
                subtitle: "Use Apple Intelligence to understand screenshots privately on your device.",
                isOn: $onDeviceAnalysis
            )
        }
    }

    private var privacySection: some View {
        SettingsSection(title: "Privacy") {
            SettingsNavigationRow(
                icon: "cpu",
                title: "On-Device AI",
//                subtitle: "How Side-B understands your Tracks"
            ) {
                showOnDeviceAIInfo = true
            }

            SettingsDivider()

            SettingsNavigationRow(
                icon: "externaldrive",
                title: "Manage Side-B Data",
//                subtitle: "Review or clear locally stored Side-B data"
            ) {
                showManageData = true
            }

            SettingsDivider()

            SettingsNavigationRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                trailingSystemImage: "arrow.up.right.square"
            ) {
                openPrivacyPolicy()
            }
        }
    }

    private var generalSection: some View {
        SettingsSection(title: "General") {
            SettingsNavigationRow(
                icon: "info.circle",
                title: "About Side-B"
            ) {
                showAbout = true
            }
        }
    }

    private var photoPermissionText: String { viewModel.photosAccess.label }

    private func handlePhotoPermission() {
        switch viewModel.photosAccess {
        case .notDetermined: explainPhotos = true
        case .limited: viewModel.managePhotoAccess()
        case .authorized, .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        case .restricted: break
        }
    }

    private func openPrivacyPolicy() {
        if let privacyPolicyURL { UIApplication.shared.open(privacyPolicyURL) }
    }
}
