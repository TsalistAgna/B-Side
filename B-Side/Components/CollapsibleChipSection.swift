//
//  CollapsibleChipSection.swift
//  B-Side
//

import SwiftUI

struct CollapsibleChipSection: View {
    let title: String
    let items: [String]
    let selectedItems: Set<String>
    let collapsedLimit: Int
    let showsAllChip: Bool
    let titleFontSize: CGFloat
    @Binding var isExpanded: Bool
    let onSelect: (String) -> Void
    let onSelectAll: (() -> Void)?

    init(
        title: String,
        items: [String],
        selectedItems: Set<String>,
        collapsedLimit: Int = 6,
        showsAllChip: Bool = false,
        titleFontSize: CGFloat = 20,
        isExpanded: Binding<Bool>,
        onSelect: @escaping (String) -> Void,
        onSelectAll: (() -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.selectedItems = selectedItems
        self.collapsedLimit = collapsedLimit
        self.showsAllChip = showsAllChip
        self.titleFontSize = titleFontSize
        _isExpanded = isExpanded
        self.onSelect = onSelect
        self.onSelectAll = onSelectAll
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text(title)
                    .font(.system(size: titleFontSize, weight: .semibold))
                    .foregroundStyle(Color.bSideDarkBlue)

                Spacer()

                if items.count > collapsedLimit {
                    Button(isExpanded ? "Show Less" : "See All") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.bSideBlue)
                    .buttonStyle(.plain)
                }
            }

            TagFlowLayout(spacing: 9) {
                if showsAllChip {
                    chip(
                        title: "All",
                        isSelected: selectedItems.isEmpty
                    ) {
                        onSelectAll?()
                    }
                }

                ForEach(visibleItems, id: \.self) { item in
                    chip(
                        title: item,
                        isSelected: selectedItems.contains(item)
                    ) {
                        onSelect(item)
                    }
                }
            }
        }
    }

    private var visibleItems: [String] {
        guard !isExpanded else {
            return items
        }

        let selected = items.filter { selectedItems.contains($0) }
        let unselected = items.filter { !selectedItems.contains($0) }
        let remainingSlots = max(collapsedLimit - selected.count, 0)

        return selected + unselected.prefix(remainingSlots)
    }

    private func chip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : Color.bSideDarkBlue)
                .padding(.horizontal, 16)
                .frame(height: 40)
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
