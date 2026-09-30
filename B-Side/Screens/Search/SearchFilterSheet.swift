//
//  SearchFilterSheet.swift
//  B-Side
//

import SwiftUI

enum SearchDateFilter: String, CaseIterable, Identifiable {
    case anytime = "Anytime"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"

    var id: Self { self }
}

enum SearchSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"

    var id: Self { self }
}

struct SearchFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let categories: [String]
    let onApply: (Set<String>, SearchDateFilter, SearchSortOption) -> Void

    @State private var selectedCategories: Set<String>
    @State private var selectedDateFilter: SearchDateFilter
    @State private var sortOption: SearchSortOption
    @State private var showAllCategories = false

    private let collapsedCategoryLimit = 6

    init(
        categories: [String],
        selectedCategories: Set<String>,
        selectedDateFilter: SearchDateFilter,
        sortOption: SearchSortOption,
        onApply: @escaping (Set<String>, SearchDateFilter, SearchSortOption) -> Void
    ) {
        self.categories = categories
        self.onApply = onApply
        _selectedCategories = State(initialValue: selectedCategories)
        _selectedDateFilter = State(initialValue: selectedDateFilter)
        _sortOption = State(initialValue: sortOption)
    }

    var body: some View {
        ZStack {
            Color.bSideBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Search Filter")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.bSideDarkBlue)
                        .frame(maxWidth: .infinity)

                    CollapsibleChipSection(
                        title: "Collection",
                        items: categories,
                        selectedItems: selectedCategories,
                        collapsedLimit: collapsedCategoryLimit,
                        showsAllChip: true,
                        titleFontSize: 17,
                        isExpanded: $showAllCategories,
                        onSelect: toggleCategory,
                        onSelectAll: {
                            selectedCategories.removeAll()
                        }
                    )

                    filterSection(title: "Saved") {
                        TagFlowLayout(spacing: 9) {
                            ForEach(SearchDateFilter.allCases) { option in
                                FilterChip(
                                    title: option.rawValue,
                                    isSelected: selectedDateFilter == option
                                ) {
                                    selectedDateFilter = option
                                }
                            }
                        }
                    }

                    filterSection(title: "Sort by") {
                        HStack(spacing: 9) {
                            ForEach(SearchSortOption.allCases) { option in
                                FilterChip(
                                    title: option.rawValue,
                                    isSelected: sortOption == option
                                ) {
                                    sortOption = option
                                }
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        Button {
                            onApply(
                                selectedCategories,
                                selectedDateFilter,
                                sortOption
                            )
                            dismiss()
                        } label: {
                            Text("Apply Filter")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.bSideBlue)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button("Reset") {
                            selectedCategories.removeAll()
                            selectedDateFilter = .anytime
                            sortOption = .newest
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.bSideBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay {
                            Capsule()
                                .stroke(Color.blue4, lineWidth: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
    }

    private func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.bSideDarkBlue)

            content()
        }
    }

    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : Color.bSideDarkBlue)
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(isSelected ? Color.bSideBlue : Color.blue1)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(
                            isSelected ? Color.bSideBlue : Color.blue4,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
