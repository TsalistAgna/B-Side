//
//  SearchView.swift
//  B-Side
//

import SwiftUI
import UIKit

struct SearchView: View {
    @ObservedObject var viewModel: HomeViewModel

    @State private var searchText = ""
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDateFilter: SearchDateFilter = .anytime
    @State private var sortOption: SearchSortOption = .newest
    @State private var showFilterSheet = false
    @State private var selectedTrack: Track?
    @State private var showAllCategories = false

    private let collapsedCategoryLimit = 6

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 14),
            count: dynamicTypeSize >= .xxxLarge ? 1 : 2
        )
    }

    var body: some View {
        ZStack {
            Color.bSideBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Search")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.textPrimary)

                    SearchBar(
                        searchText: $searchText,
                        activeFilterCount: activeFilterCount,
                        onFilter: { showFilterSheet = true }
                    )

                    if viewModel.processedLibraryTracks.isEmpty {
                        SearchEmptyState(
                            title: "Nothing to search yet",
                            message: "Once your screenshots become Tracks,\nyou'll be able to find them here."
                        )
                    } else if isRetrieving {
                        searchResults
                    } else {
                        idleContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, BSideLayout.spacingXL)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showFilterSheet) {
            SearchFilterSheet(
                categories: categoryNames,
                selectedCategories: selectedCategories,
                selectedDateFilter: selectedDateFilter,
                sortOption: sortOption
            ) { categories, dateFilter, newSortOption in
                selectedCategories = categories
                selectedDateFilter = dateFilter
                sortOption = newSortOption
            }
            .presentationDetents([.fraction(0.78), .large])
            .presentationCornerRadius(BSideLayout.radiusSheet)
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedTrack) { track in
            TrackDetailSheet(
                track: track,
                viewModel: viewModel
            )
            .presentationDetents([.large])
            .presentationCornerRadius(BSideLayout.radiusSheet)
            .presentationDragIndicator(.visible)
        }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            if !categoryNames.isEmpty {
                CollapsibleChipSection(
                    title: "Browse your Side-Bs",
                    items: categoryNames,
                    selectedItems: selectedCategories,
                    collapsedLimit: collapsedCategoryLimit,
                    unselectedFill: Color.surfaceSecondary.opacity(0.45),
                    isExpanded: $showAllCategories
                ) { category in
                    selectedCategories = [category]
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Recently Saved")
                trackGrid(recentTracks)
            }
        }
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(resultCountText)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            if filteredTracks.isEmpty {
                SearchEmptyState(
                    title: "No Tracks found",
                    message: "Try another keyword or adjust your filters."
                )
            } else {
                trackGrid(filteredTracks)
            }
        }
    }

    private func trackGrid(_ tracks: [Track]) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(tracks) { track in
                SearchTrackCard(
                    track: track,
                    loadImage: viewModel.image(for:)
                ) {
                    selectedTrack = track
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.textPrimary)
    }

    private var categoryNames: [String] {
        viewModel.collections.map(\.name)
    }

    private var recentTracks: [Track] {
        Array(
            viewModel.processedLibraryTracks
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(6)
        )
    }

    private var filteredTracks: [Track] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedKeys = Set(
            selectedCategories.map {
                CategoryNameNormalizer.comparisonKey(for: $0)
            }
        )
        let calendar = Calendar.current
        let now = Date()

        return viewModel.processedLibraryTracks
            .filter { track in
                matchesQuery(track, query: query) &&
                matchesCategory(track, selectedKeys: selectedKeys) &&
                matchesDate(track.createdAt, calendar: calendar, now: now)
            }
            .sorted {
                sortOption == .newest
                    ? $0.createdAt > $1.createdAt
                    : $0.createdAt < $1.createdAt
            }
    }

    private func matchesQuery(_ track: Track, query: String) -> Bool {
        guard !query.isEmpty else { return true }

        let searchableValues = [
            track.title,
            track.detailDescription,
            track.rediscoveryDescription,
            track.categoryName
        ].compactMap { $0 } + track.tags

        return searchableValues.contains {
            $0.localizedCaseInsensitiveContains(query)
        }
    }

    private func matchesCategory(
        _ track: Track,
        selectedKeys: Set<String>
    ) -> Bool {
        guard !selectedKeys.isEmpty else { return true }
        guard let categoryName = track.categoryName else { return false }
        return selectedKeys.contains(
            CategoryNameNormalizer.comparisonKey(for: categoryName)
        )
    }

    private func matchesDate(
        _ date: Date,
        calendar: Calendar,
        now: Date
    ) -> Bool {
        switch selectedDateFilter {
        case .anytime:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) ?? false
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.contains(date) ?? false
        }
    }

    private var isRetrieving: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !selectedCategories.isEmpty ||
        selectedDateFilter != .anytime ||
        sortOption != .newest
    }

    private var activeFilterCount: Int {
        selectedCategories.count +
        (selectedDateFilter == .anytime ? 0 : 1) +
        (sortOption == .newest ? 0 : 1)
    }

    private var resultCountText: String {
        let count = filteredTracks.count
        return "\(count) \(count == 1 ? "Track" : "Tracks") found"
    }
}

private struct SearchBar: View {
    @Binding var searchText: String
    let activeFilterCount: Int
    let onFilter: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .accessibilityHidden(true)
                    .foregroundStyle(Color.textSecondary)

                TextField("Search what you saved...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.textPrimary)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surfaceSecondary.opacity(0.45))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDefault, lineWidth: 1)
            }

            Button(action: onFilter) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.accentText)
                        .frame(width: 52, height: 52)
                        .background(Color.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.borderDefault, lineWidth: 1)
                        }

                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.accentPrimary)
                            .clipShape(Circle())
                            .offset(x: 5, y: -5)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search filters")
            .accessibilityValue(activeFilterCount == 0 ? "No active filters" : "\(activeFilterCount) active")
        }
    }
}

private struct SearchTrackCard: View {
    let track: Track
    let loadImage: (String) async -> UIImage?
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onTap) {
            TrackCollectionCard(
                track: Track(
                    id: track.id,
                    image: thumbnail ?? track.image,
                    createdAt: track.createdAt,
                    title: track.title,
                    rediscoveryDescription: track.rediscoveryDescription,
                    detailDescription: track.detailDescription,
                    tags: track.tags,
                    categoryName: track.categoryName
                )
            )
        }
        .buttonStyle(.plain)
        .task(id: track.id) {
            guard track.image == nil else { return }
            thumbnail = await loadImage(track.id)
        }
    }
}

private struct SearchEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.and.text.magnifyingglass")
                .accessibilityHidden(true)
                .font(.system(size: 32))
                .foregroundStyle(Color.accentText)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 54)
    }
}
