//
//  HomeView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import Photos

struct HomeView: View {

    @ObservedObject
    var viewModel: HomeViewModel
    
    @State private var selectedTrack: Track?


    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: dynamicTypeSize >= .xxxLarge ? 2 : 4
        )
    }


    var body: some View {

        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()


            mainContent
        }
    }


    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {

        if viewModel.isLoading {

            ProgressView(
                "Finding your tracks..."
            )

        } else if viewModel.tracks.isEmpty {

            EmptyHomeView(
                permissionStatus:
                    viewModel.permissionStatus
            ) {

                handleAddScreenshot()
            }

        } else {

            homeContent
        }
    }


    // MARK: - Home Content

    private var homeContent: some View {

        ScrollView(
            showsIndicators: false
        ) {

            VStack(spacing: 24) {


                // MARK: Today's Finding

                if let finding = viewModel.todaysFinding {

                    Button {
                        selectedTrack = finding
                    } label: {
                        DailyFindingCard(
                            track: finding
                        )
                    }
                    .buttonStyle(.plain)
                } else {

                    waitingForFindingView
                }


                // MARK: Latest Track

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    Text("Latest Track")
                        .font(
                            .title2.weight(.semibold)
                        )
                        .foregroundStyle(
                            Color.textPrimary
                        )


                    LazyVGrid(
                        columns: columns,
                        spacing: 10
                    ) {

                        ForEach(
                            viewModel.latestTracks
                        ) { track in

                            Button {

                                selectedTrack = track

                            } label: {

                                TrackThumbnail(
                                    track: track
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)

            // The tab bar reserves its own safe-area space.
            .padding(.bottom, BSideLayout.spacingXL)
        }
        .sheet(
            item: $selectedTrack
        ) { track in

            TrackDetailSheet(
                track: track,
                viewModel: viewModel
            )
            .presentationDetents([
                .fraction(0.7),
                .large
            ])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(BSideLayout.radiusSheet)
        }
    }


    // MARK: - Waiting For AI

    private var waitingForFindingView: some View {

        VStack(spacing: 12) {

            Text("Today’s Rediscovery")
                .font(
                    .title2.weight(.semibold)
                )
                .foregroundStyle(
                    Color.textPrimary
                )


            if viewModel.isAnalyzing {

                ProgressView()

                Text(
                    "Side-B is organizing your tracks..."
                )
                .font(.subheadline)
                .foregroundStyle(
                    Color.textSecondary
                )

            } else {

                Image(
                    systemName: "sparkles"
                )
                .accessibilityHidden(true)
                .font(
                    .system(size: 34)
                )
                .foregroundStyle(
                    Color.accentPrimary
                )


                Text("Nothing to Rediscover Yet")
                Text("Your daily Track will appear after you add more screenshots.")
                .font(.subheadline)
                .foregroundStyle(
                    Color.textSecondary
                )
            }
        }
        .padding(.vertical, 20)
    }


    // MARK: - Add Screenshots

    private func handleAddScreenshot() {
        switch viewModel.photosAccess {
        case .notDetermined: Task { await viewModel.requestPermission() }
        case .denied: openSettings()
        case .limited: viewModel.managePhotoAccess()
        case .authorized: Task { await viewModel.refreshAccessiblePhotos() }
        case .restricted: break
        }
    }


    // MARK: - Open Settings

    private func openSettings() {

        guard let url = URL(
            string: UIApplication.openSettingsURLString
        )
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}


#Preview {

    HomeView(
        viewModel: HomeViewModel()
    )
}
