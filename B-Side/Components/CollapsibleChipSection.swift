//
//  CollapsibleChipSection.swift
//  Side-B
//

import SwiftUI

struct CollapsibleChipSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let items: [String]
    let selectedItems: Set<String>
    let collapsedLimit: Int
    let showsAllChip: Bool
    let titleFont: Font
    let unselectedFill: Color
    @Binding var isExpanded: Bool
    let onSelect: (String) -> Void
    let onSelectAll: (() -> Void)?

    init(
        title: String,
        items: [String],
        selectedItems: Set<String>,
        collapsedLimit: Int = 6,
        showsAllChip: Bool = false,
        titleFont: Font = .title3,
        unselectedFill: Color = .surfaceSecondary,
        isExpanded: Binding<Bool>,
        onSelect: @escaping (String) -> Void,
        onSelectAll: (() -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.selectedItems = selectedItems
        self.collapsedLimit = collapsedLimit
        self.showsAllChip = showsAllChip
        self.titleFont = titleFont
        self.unselectedFill = unselectedFill
        _isExpanded = isExpanded
        self.onSelect = onSelect
        self.onSelectAll = onSelectAll
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            headerLayout {
                Text(title)
                    .font(titleFont.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                if items.count > collapsedLimit {
                    Button {
                        if reduceMotion {
                            isExpanded.toggle()
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }
                    } label: {
                        Text(isExpanded ? "Show Less" : "See All")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.accentText)
                            .frame(minWidth: BSideLayout.minimumTouchTarget, minHeight: BSideLayout.minimumTouchTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                }
            }

            TagFlowLayout(spacing: 9) {
                if showsAllChip {
                    chip(title: "All", isSelected: selectedItems.isEmpty) {
                        onSelectAll?()
                    }
                }

                ForEach(visibleItems, id: \.self) { item in
                    chip(title: item, isSelected: selectedItems.contains(item)) {
                        onSelect(item)
                    }
                }
            }
        }
    }

    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
    }

    private var visibleItems: [String] {
        guard !isExpanded else { return items }

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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.accentForeground : Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minHeight: BSideLayout.minimumTouchTarget)
                .background {
                    RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2).fill(isSelected ? Color.accentPrimary : unselectedFill)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2)
                        .stroke(isSelected ? Color.accentPrimary : Color.borderDefault, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
