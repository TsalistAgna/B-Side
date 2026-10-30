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
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)

                    CollapsibleChipSection(
                        title: "Collection",
                        items: categories,
                        selectedItems: selectedCategories,
                        collapsedLimit: collapsedCategoryLimit,
                        showsAllChip: true,
                        titleFont: .headline,
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
                        TagFlowLayout(spacing: 9) {
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
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(minHeight: BSideLayout.buttonMinimumHeight)
                                .background(Color.accentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2))
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedCategories.removeAll()
                            selectedDateFilter = .anytime
                            sortOption = .newest
                        } label: {
                        Text("Reset")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: BSideLayout.buttonMinimumHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2)
                                .stroke(Color.borderDefault, lineWidth: 1)
                        }
                        .contentShape(Rectangle())
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
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: BSideLayout.buttonMinimumHeight)
                .background(isSelected ? Color.accentPrimary : Color.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2))
                .overlay {
                    RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2)
                        .stroke(
                            isSelected ? Color.accentPrimary : Color.borderDefault,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
